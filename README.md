# CineBook – Movie Ticket Booking App

A full-stack, production-ready movie ticket booking application built as a learning project.

| Layer | Technology |
|-------|-----------|
| **Frontend** | React 18 + Vite + Tailwind CSS |
| **Backend** | Java 17 + Spring Boot 3 + Spring Security (JWT) |
| **Database** | MySQL 8 (RDS Free Tier) · H2 in-memory for local dev |
| **Storage** | AWS S3 (movie posters) |
| **CI/CD** | GitHub → AWS CodePipeline → CodeBuild → CodeDeploy → EC2 |
| **AI Feature** | In-app content-based + collaborative-filtering recommendation engine |

---

## Architecture

```
Browser (React SPA)
       │
       │ HTTPS
       ▼
  EC2 t2.micro
  Spring Boot :8080
       │
       ├── MySQL RDS db.t3.micro (private subnet)
       └── S3  (movie posters – presigned URLs)

GitHub
  └── CodePipeline
        ├── CodeBuild  (build React + Spring Boot)
        └── CodeDeploy (deploy JAR to EC2)
```

### AWS Free Tier Usage

| Service | Free Tier |
|---------|-----------|
| EC2 t2.micro | 750 hrs/month (12 months) |
| RDS db.t3.micro MySQL | 750 hrs/month (12 months) |
| S3 | 5 GB storage, 20 K GET, 2 K PUT |
| CodeBuild | 100 build min/month |
| CodePipeline | 1 active pipeline free |
| CodeDeploy | Free for EC2 |

---

## Repository Structure

```
movieBookApp/
├── movie-booking-backend/        ← Spring Boot Maven project
│   ├── src/main/java/com/moviebooking/
│   │   ├── entity/               User, Movie, Show, Seat, Booking
│   │   ├── repository/           JPA repositories
│   │   ├── service/              AuthService, MovieService, ShowService,
│   │   │                         BookingService, AIRecommendationService
│   │   ├── controller/           REST controllers (Auth, Movie, Show, Booking, Admin, AI)
│   │   ├── security/             JWT filter, JwtUtils, UserDetailsService
│   │   └── config/               SecurityConfig, AwsConfig, GlobalExceptionHandler
│   ├── src/main/resources/
│   │   ├── application.yml       Local / H2
│   │   └── application-prod.yml  Production / MySQL (uses env vars)
│   ├── Dockerfile
│   └── pom.xml
│
├── movie-booking-frontend/       ← React + Vite + Tailwind project
│   ├── src/
│   │   ├── api/index.js          Axios client + all API calls
│   │   ├── context/AuthContext   JWT stored in localStorage
│   │   ├── components/           Navbar, MovieCard, SeatGrid, AIRecommendations
│   │   └── pages/                Home, Login, Signup, MovieDetail,
│   │                              SeatSelection, BookingHistory, AdminDashboard
│   ├── vite.config.js
│   └── package.json
│
├── buildspec.yml                 CodeBuild – builds both projects
├── appspec.yml                   CodeDeploy – deploys Spring Boot to EC2
├── .aws/
│   ├── scripts/                  stop/start/validate shell scripts
│   └── cloudformation/
│       └── infrastructure.yml   Full IaC: VPC, EC2, RDS, S3, Pipeline
└── README.md
```

---

## Core Features

### User
- Signup / Login (JWT-based, BCrypt passwords)
- Browse movies with search & genre filter
- View movie details and available shows
- Interactive seat grid – pick 1–5 seats per booking
- Booking history with cancellation support
- **AI Recommendations** – personalised picks based on booking history + genre affinity + popularity

### Admin
- Add / update / delete movies (with S3 poster upload)
- Add / delete shows (seats auto-generated)

---

## Local Development

### Prerequisites

- Java 17+
- Node.js 20+
- Maven 3.9+

### Backend

```bash
cd movie-booking-backend
./mvnw spring-boot:run
# App starts on http://localhost:8080
# H2 console: http://localhost:8080/h2-console
# Seed data: admin/Admin@1234 · john/User@1234
```

### Frontend

```bash
cd movie-booking-frontend
cp .env.example .env      # VITE_API_BASE_URL=/api (proxied by Vite to :8080)
npm install
npm run dev
# App starts on http://localhost:3000
```

---

## REST API Reference

### Auth
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/signup` | Public | Register |
| POST | `/api/auth/login` | Public | Login → JWT |

### Movies
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/movies` | Public | List / search / filter |
| GET | `/api/movies/genres` | Public | All genres |
| GET | `/api/movies/{id}` | Public | Movie detail |
| GET | `/api/movies/{id}/shows` | Public | Upcoming shows |

### Shows & Seats
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/shows/{id}` | Public | Show detail |
| GET | `/api/shows/{id}/seats` | Public | Seat layout |

### Bookings
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/bookings/my` | User | My bookings |
| POST | `/api/bookings` | User | Create booking (1–5 seats) |
| DELETE | `/api/bookings/{id}/cancel` | User | Cancel booking |

### AI
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/ai/recommendations` | User | Personalised movie picks |

### Admin (requires ROLE_ADMIN)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/admin/movies` | Create movie + poster |
| PUT | `/api/admin/movies/{id}` | Update movie |
| DELETE | `/api/admin/movies/{id}` | Soft-delete movie |
| POST | `/api/admin/shows` | Create show (auto-generates seats) |
| DELETE | `/api/admin/shows/{id}` | Soft-delete show |

---

## AI Recommendation Engine

The recommendation engine runs entirely in the JVM (**no external API calls, 100% free tier**).

**Strategy (scored composite):**

1. **Genre affinity** – Weight movies in genres you have booked most
2. **Popularity boost** – Surface the most-booked movies across all users
3. **Rating boost** – Favour higher-rated titles within matched genres
4. **Exclusions** – Already-watched movies are excluded

Each recommendation comes with a human-readable `reason` field (e.g. "Because you enjoy Sci-Fi movies").

---

## AWS Deployment Guide

### 1. Deploy CloudFormation stack

```bash
aws cloudformation deploy \
  --template-file .aws/cloudformation/infrastructure.yml \
  --stack-name moviebooking-stack \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      GitHubOwner=<your-github-username> \
      GitHubRepo=movieBookApp \
      GitHubBranch=main \
      GitHubConnectionArn=<codestar-connection-arn> \
      DBPassword=<strong-password> \
      KeyPairName=<your-ec2-keypair>
```

### 2. Store secrets in SSM Parameter Store

```bash
aws ssm put-parameter --name /moviebooking/prod/db-host     --value "<rds-endpoint>" --type SecureString
aws ssm put-parameter --name /moviebooking/prod/db-port     --value "3306"            --type String
aws ssm put-parameter --name /moviebooking/prod/db-name     --value "moviebookingdb"  --type String
aws ssm put-parameter --name /moviebooking/prod/db-user     --value "admin"           --type SecureString
aws ssm put-parameter --name /moviebooking/prod/db-password --value "<db-password>"   --type SecureString
aws ssm put-parameter --name /moviebooking/prod/jwt-secret  --value "<32-char-secret>" --type SecureString
aws ssm put-parameter --name /moviebooking/prod/s3-bucket   --value "<bucket-name>"   --type String
aws ssm put-parameter --name /moviebooking/prod/aws-region  --value "us-east-1"       --type String
aws ssm put-parameter --name /moviebooking/prod/api-url     --value "http://<ec2-dns>:8080" --type String
```

### 3. Initialise the RDS schema

```bash
# Run from EC2 or bastion after Flyway/Liquibase migrations, or let JPA
# create the schema on first boot (spring.jpa.hibernate.ddl-auto=update)
```

### 4. Push code – pipeline triggers automatically

```bash
git push origin main
# CodePipeline: Source → Build → Deploy
```

### 5. Deploy the React frontend to S3

```bash
cd movie-booking-frontend
VITE_API_BASE_URL=http://<ec2-dns>:8080/api npm run build
aws s3 sync dist/ s3://moviebooking-frontend-<account-id> --delete
```

---

## Security Highlights

- Passwords hashed with **BCrypt** (strength 12)
- **JWT** tokens (24 h expiry, HMAC-SHA256)
- All secrets injected via **SSM Parameter Store** – never in source code
- CORS restricted to known origins
- Input validation via Jakarta Bean Validation on every API
- RDS in **private subnet** – not publicly accessible
- S3 poster bucket **blocks all public access** (served via presigned URLs)
- EC2 Security Group denies SSH from the internet; use **AWS Systems Manager Session Manager** instead in production

---

## Extending the App

| Feature | How |
|---------|-----|
| Email confirmations | Add Spring Mail + AWS SES |
| Payment simulation | Add a `/api/payments` mock endpoint |
| Real-time seat updates | Add Spring WebSocket + STOMP |
| Upgrade AI | Swap `AIRecommendationService` with AWS Bedrock (Titan / Claude) |
| HTTPS | Put an AWS ALB + ACM certificate in front of EC2 |
| CDN for frontend | Move S3 behind CloudFront |
