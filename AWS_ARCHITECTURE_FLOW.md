# AWS Architecture: CloudFront, S3 & RDS – Detailed Flow

## Overview

```
                    ┌─────────────────────────────────────────────────────────┐
                    │                    USER'S BROWSER                        │
                    │         (https://xxxxx.cloudfront.net)                    │
                    └─────────────────────────┬───────────────────────────────┘
                                              │
                                              ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                           CLOUDFRONT (CDN – Single Entry Point)                                   │
│                                                                                                   │
│   Path-based routing:                                                                             │
│   • /*          →  S3 (frontend)                                                                  │
│   • /api/*      →  EC2 (backend)                                                                   │
└───────────────┬───────────────────────────────────────────┬─────────────────────────────────────┘
                │                                           │
                ▼                                           ▼
┌───────────────────────────────┐              ┌───────────────────────────────┐
│  S3 FRONTEND BUCKET           │              │  EC2 BACKEND (Spring Boot)    │
│  • index.html                 │              │  • REST API (JWT, Bookings)    │
│  • JS, CSS assets             │              │  • Connects to RDS + S3       │
└───────────────────────────────┘              └───────────┬──────────┬────────┘
                                                           │          │
                                                           ▼          ▼
                                              ┌───────────────┐  ┌───────────────────┐
                                              │  RDS MySQL    │  │  S3 POSTERS BUCKET │
                                              │  • Users      │  │  • Movie poster    │
                                              │  • Movies     │  │    images          │
                                              │  • Shows      │  └───────────────────┘
                                              │  • Bookings   │
                                              └───────────────┘
```

---

## 1. CloudFront (CDN)

### Role
CloudFront is the single public URL for the app. It decides whether each request goes to S3 (frontend) or EC2 (backend).

### Configuration
- **One distribution** with two origins: S3 and EC2
- **Path-based routing**:
  - `/*` → S3 (static frontend)
  - `/api/*` → EC2 (backend API)

### Request Flow

| User requests                    | CloudFront forwards to | Origin response   |
|----------------------------------|------------------------|-------------------|
| `GET /`                          | S3                     | index.html        |
| `GET /login`                     | S3                     | index.html (SPA)  |
| `GET /api/movies`                | EC2:8080               | JSON movie list   |
| `POST /api/bookings`             | EC2:8080               | Booking created   |
| `GET /api/movies/1/poster-url`   | EC2:8080               | Presigned S3 URL  |

### Features
- **HTTPS**: Uses AWS default certificate (*.cloudfront.net)
- **SPA support**: 404/403 responses are rewritten to `/index.html` for client-side routing
- **Caching**: S3 responses cached; API responses cached for GET only (headers like Authorization forwarded)
- **Compression**: Responses are compressed

### Why CloudFront?
- Single domain avoids CORS
- Global caching for static assets
- HTTPS without managing certificates
- Acts as reverse proxy for the backend

---

## 2. S3 Buckets (Three Buckets)

### (A) Frontend Bucket

**Purpose:** Store the React SPA build (HTML, JS, CSS).

| Flow step | What happens |
|-----------|--------------|
| Deploy    | CodeBuild runs `npm run build` and `aws s3 sync dist/` to the frontend bucket (or manual equivalent) |
| Request   | User asks for `GET /` or `GET /assets/main.js` |
| CloudFront| Sends request to S3 origin |
| S3        | Returns the file |
| Access    | Only CloudFront can read (OAC); bucket is not public |

**Contents:**
```
index.html
assets/
  ├── index-[hash].js
  ├── index-[hash].css
  └── ...
```

---

### (B) Artifacts Bucket

**Purpose:** Store the backend JAR for EC2.

| Flow step | What happens |
|-----------|--------------|
| Deploy    | CodeBuild runs `mvn package`, uploads JAR to artifacts bucket, CodeDeploy copies `app.jar` to EC2 |
| EC2 boot  | User data runs `aws s3 cp s3://artifacts-bucket/... app.jar` |
| EC2 start | `start.sh` downloads JAR and runs `java -jar app.jar` |

**Access:** EC2 has an IAM role that allows `s3:GetObject` on this bucket.

---

### (C) Posters Bucket

**Purpose:** Store movie poster images uploaded by admins.

| Flow step | What happens |
|-----------|--------------|
| Admin add movie | Frontend sends `POST /api/admin/movies` with image file |
| Backend        | `MovieService` uploads to S3: `s3Client.putObject(bucket, key, bytes)` |
| DB             | Movie row saves `poster_key` (e.g. `posters/uuid-filename.jpg`) |
| User views movie | Frontend calls `GET /api/movies/{id}/poster-url` |
| Backend        | Returns a presigned URL (valid ~1 hour) for the poster in S3 |
| Frontend       | Sets `<img src={presignedUrl}>` |
| Browser        | Fetches image directly from S3 via presigned URL |

**Security:** Bucket is private. Only presigned URLs allow temporary read access.

**Access:** EC2 role has `s3:PutObject`, `s3:GetObject`, `s3:DeleteObject` on the posters bucket.

---

## 3. RDS MySQL

### Role
Database for the whole app: users, movies, shows, seats, bookings.

### Deployment
- **Engine:** MySQL 8.0
- **Class:** db.t3.micro
- **Storage:** 20 GB gp2
- **Network:** Private subnets only; not internet-accessible
- **Access:** Only from EC2 (security group allows 3306 from backend SG)

### Schema (conceptually)
```
app_users      → Users (admin, john, jane)
movies         → Movie metadata (poster_key points to S3)
movie_shows    → Show timings per movie
seats          → Seats per show (A1, A2, ...)
bookings       → User bookings
booking_seats  → Seat numbers per booking
```

### Request Flow (API → RDS)

| User action      | API call              | Backend → RDS |
|------------------|-----------------------|---------------|
| Login            | `POST /api/auth/login`| `SELECT * FROM app_users WHERE username=?` |
| List movies      | `GET /api/movies`     | `SELECT * FROM movies WHERE active=true`   |
| View show times  | `GET /api/movies/1/shows` | `SELECT * FROM movie_shows WHERE movie_id=1` |
| Book seats       | `POST /api/bookings`  | `INSERT INTO bookings`, `UPDATE seats`     |
| Admin add movie  | `POST /api/admin/movies` | `INSERT INTO movies`, upload poster to S3  |

### Connection
- Spring Boot uses JDBC with HikariCP
- Connection string: `jdbc:mysql://<rds-endpoint>:3306/moviebookingdb`
- Credentials come from env vars on EC2 (`DB_HOST`, `DB_USER`, `DB_PASSWORD`)

---

## 4. End-to-End Flows

### A. User opens the app
```
Browser → GET https://xxx.cloudfront.net/
       → CloudFront (path /) → S3 → index.html
       → Browser loads → fetches /assets/*.js
       → CloudFront → S3 → JS/CSS
       → App renders
```

### B. User logs in
```
Browser → POST https://xxx.cloudfront.net/api/auth/login
       → CloudFront (path /api/*) → EC2:8080
       → Spring Boot → RDS: SELECT user, verify password
       → Returns JWT
       → Frontend stores token
```

### C. User browses movies
```
Browser → GET https://xxx.cloudfront.net/api/movies
       → CloudFront → EC2
       → Spring Boot → RDS: SELECT * FROM movies
       → Returns JSON
       → For each movie with poster: GET /api/movies/{id}/poster-url
       → Backend returns presigned S3 URL
       → Browser loads image directly from S3
```

### D. User books seats
```
Browser → POST https://xxx.cloudfront.net/api/bookings
       → CloudFront → EC2 (with JWT in header)
       → Spring Boot validates JWT
       → RDS: INSERT booking, UPDATE seats
       → Returns confirmation
```

### E. Admin adds movie with poster
```
Browser → POST https://xxx.cloudfront.net/api/admin/movies (multipart: movie + poster image)
       → CloudFront → EC2 (with admin JWT)
       → Spring Boot: upload image to S3 Posters bucket (PutObject)
       → RDS: INSERT INTO movies (poster_key = s3_key)
       → Returns movie
```

---

## Summary Table

| Service    | Purpose                                | Who accesses it                    |
|------------|----------------------------------------|-----------------------------------|
| CloudFront | Single HTTPS entry, route to S3/EC2    | Users (browser)                   |
| S3 Frontend| React build (HTML/JS/CSS)              | CloudFront only                   |
| S3 Artifacts | Backend JAR                          | EC2 only (via IAM role)           |
| S3 Posters| Movie poster images                    | EC2 (upload); Users (presigned)   |
| RDS MySQL | All application data                  | EC2 only (private subnet)         |
