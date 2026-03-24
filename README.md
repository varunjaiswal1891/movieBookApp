# CineBook – Movie Ticket Booking App

A full-stack movie ticket booking application with local development and AWS deployment via Terraform.

| Layer | Technology |
|-------|------------|
| **Frontend** | React 18 + Vite + Tailwind CSS |
| **Backend** | Java 17 + Spring Boot 3 + Spring Security (JWT) |
| **Database** | H2 (local) · MySQL 8 RDS (production) |
| **Storage** | AWS S3 (movie posters) |
| **Deployment** | Terraform + CodePipeline (CodeBuild, CodeDeploy) |
| **AI Feature** | In-app content-based + collaborative-filtering recommendations |

---

## Architecture

### Local Development
```
Browser (React) :3000  ←→  Vite proxy /api  →  Spring Boot :8080  →  H2 in-memory DB
```

### AWS Production (Terraform)
```
                    Browser (HTTPS)
                           │
                           ▼
                  CloudFront (CDN)
                    /         \
              /*              /api/*
               │                  │
               ▼                  ▼
        S3 (frontend)       EC2 (Spring Boot)
        index.html, JS           │
                                 ├── RDS MySQL (private subnet)
                                 └── S3 Posters (presigned URLs)
```

---

## Repository Structure

```
movieBookApp/
├── movie-booking-backend/        # Spring Boot Maven project
│   ├── src/main/java/com/moviebooking/
│   │   ├── entity/               # User, Movie, Show, Seat, Booking
│   │   ├── repository/           # JPA repositories
│   │   ├── service/              # AuthService, MovieService, ShowService, etc.
│   │   ├── controller/           # REST controllers (Auth, Movie, Show, Booking, Admin, AI)
│   │   ├── security/             # JWT filter, JwtUtils, UserDetailsService
│   │   └── config/               # SecurityConfig, AwsConfig, CorsProperties
│   ├── src/main/resources/
│   │   ├── application.yml       # Local / H2
│   │   ├── application-prod.yml  # Production / MySQL (env vars)
│   │   ├── schema.sql             # H2 schema
│   │   └── schema-mysql.sql      # MySQL schema
│   ├── Dockerfile
│   └── pom.xml
│
├── movie-booking-frontend/       # React + Vite + Tailwind
│   ├── src/
│   │   ├── api/index.js          # Axios client + API calls
│   │   ├── context/AuthContext.jsx
│   │   ├── components/           # Navbar, MovieCard, SeatGrid, AIRecommendations
│   │   └── pages/                # Home, Login, Signup, MovieDetail, SeatSelection, etc.
│   ├── vite.config.js
│   └── package.json
│
├── terraform/                    # AWS infrastructure (IaC)
│   ├── provider.tf, variables.tf, vpc.tf, rds.tf, ec2.tf, s3.tf
│   ├── cloudfront.tf, security-groups.tf, iam.tf, iam-cicd.tf
│   ├── codestar.tf, codebuild.tf, codedeploy.tf, codepipeline.tf
│   ├── outputs.tf, userdata-backend.sh
│   └── terraform.tfvars.example
│
├── buildspec.yml                 # CodeBuild – build backend + frontend
├── appspec.yml                   # CodeDeploy – backend deployment
├── scripts/
│   ├── deploy-backend.sh        # Manual: build & upload JAR
│   ├── deploy-frontend.sh       # Manual: build & upload React
│   └── codedeploy/              # CodeDeploy hooks (stop, start)
│
├── LOCAL_SETUP.md               # Run locally (no AWS)
├── TERRAFORM_DEPLOY.md          # AWS deployment guide
├── AWS_ARCHITECTURE_FLOW.md     # CloudFront, S3, RDS flow
├── AWS_COST_AND_DESTROY.md     # Cost, free tier, destroy
└── README.md
```

---

## Core Features

### User
- Signup / Login (JWT, BCrypt passwords)
- Browse movies with search & genre filter
- View movie details and available shows
- Interactive seat grid – pick 1–5 seats per booking
- Booking history with cancellation
- **AI Recommendations** – personalised picks based on booking history

### Admin
- Add / update / delete movies (S3 poster upload)
- Add / delete shows (seats auto-generated)

---

## Quick Start – Local Development

See **[LOCAL_SETUP.md](LOCAL_SETUP.md)** for full details.

```bash
# Backend
cd movie-booking-backend && mvn spring-boot:run
# → http://localhost:8080 | H2 console: /h2-console

# Frontend (new terminal)
cd movie-booking-frontend && npm install && npm run dev
# → http://localhost:3000
```

**Seed users:** `admin` / `Admin@1234` · `john` / `User@1234` · `jane` / `User@1234`

---

## AWS Deployment (Terraform + CI/CD)

See **[TERRAFORM_DEPLOY.md](TERRAFORM_DEPLOY.md)** for step-by-step instructions.

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit: db_username, db_password, jwt_secret, ssh_public_key

terraform init
terraform apply

# Authorize GitHub in AWS Console → Connections (once)
# Push to main → pipeline builds and deploys automatically
```

**App URL:** `terraform output -raw app_url`  
**Pipeline:** `terraform output pipeline_url`

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
| GET | `/api/movies/{id}/poster-url` | Public | Presigned S3 poster URL |

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

### Admin (ROLE_ADMIN)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/admin/movies` | Create movie + poster |
| PUT | `/api/admin/movies/{id}` | Update movie |
| DELETE | `/api/admin/movies/{id}` | Soft-delete movie |
| POST | `/api/admin/shows` | Create show |
| DELETE | `/api/admin/shows/{id}` | Soft-delete show |

---

## AI Recommendation Engine

Runs entirely in the JVM – **no external APIs, free tier friendly**.

**Strategy:** Genre affinity + popularity + rating boost. Excludes already-watched movies. Each recommendation includes a `reason` (e.g. "Because you enjoy Sci-Fi movies").

---

## Documentation

| Document | Description |
|----------|-------------|
| [LOCAL_SETUP.md](LOCAL_SETUP.md) | Run backend + frontend locally |
| [TERRAFORM_DEPLOY.md](TERRAFORM_DEPLOY.md) | Deploy to AWS with Terraform |
| [AWS_ARCHITECTURE_FLOW.md](AWS_ARCHITECTURE_FLOW.md) | CloudFront, S3, RDS flow |
| [AWS_COST_AND_DESTROY.md](AWS_COST_AND_DESTROY.md) | Cost, free tier, billing alerts, destroy |

---

## Security Highlights

- BCrypt passwords (strength 12)
- JWT (24 h expiry, HMAC-SHA256)
- Secrets via env vars (prod) – never in source
- CORS restricted to CloudFront / localhost
- RDS in private subnet
- S3 posters bucket private (presigned URLs only)
