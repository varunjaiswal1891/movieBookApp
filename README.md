# CineBook – Movie Ticket Booking App

A full-stack movie ticket booking application with local development and AWS deployment via Terraform.

| Layer | Technology |
|-------|------------|
| **Frontend** | React 18 + Vite + Tailwind CSS |
| **Backend** | Java 17 + Spring Boot 3 + Spring Security (JWT) |
| **Database** | H2 (local, no profile) · MySQL RDS (`stage` or `prod` on AWS) |
| **Storage** | AWS S3 (movie posters) |
| **Deployment** | Terraform + CodePipeline (CodeBuild, CodeDeploy) |
| **AI Feature** | In-app content-based + collaborative-filtering recommendations |

---

## Table of contents

1. [Architecture](#architecture)
2. [Repository structure](#repository-structure)
3. [Core features](#core-features)
4. [Spring profiles (local vs AWS)](#spring-profiles-local-vs-aws)
5. [Quick start – local](#quick-start--local)
6. [Local setup (detailed)](#local-setup-detailed)
7. [AWS deployment (Terraform + CI/CD)](#aws-deployment-terraform--cicd)
8. [Spring profile on EC2](#spring-profile-on-ec2)
9. [AWS architecture (CloudFront, S3, RDS)](#aws-architecture-cloudfront-s3-rds)
10. [AWS cost, free tier, destroy](#aws-cost-free-tier-destroy)
11. [Secrets Manager for `terraform.tfvars`](#secrets-manager-for-terraformtfvars)
12. [REST API reference](#rest-api-reference)
13. [AI recommendation engine](#ai-recommendation-engine)
14. [Security highlights](#security-highlights)

---

## Architecture

### Local development

```
Browser (React) :3000  ←→  Vite proxy /api  →  Spring Boot :8080  →  H2 in-memory DB
```

### AWS (Terraform)

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

## Repository structure

```
movieBookApp/
├── movie-booking-backend/        # Spring Boot Maven project
│   ├── src/main/java/com/moviebooking/
│   ├── src/main/resources/
│   │   ├── application.yml         # Local / H2
│   │   ├── application-stage.yml   # Staging / MySQL (env)
│   │   ├── application-prod.yml    # Production / MySQL (env)
│   │   ├── schema.sql
│   │   └── schema-mysql.sql
│   ├── Dockerfile
│   └── pom.xml
├── movie-booking-frontend/       # React + Vite + Tailwind
├── terraform/                    # AWS infrastructure (IaC)
│   ├── provider.tf, variables.tf, vpc.tf, rds.tf, ec2.tf, s3.tf
│   ├── cloudfront.tf, security-groups.tf, iam.tf, iam-cicd.tf
│   ├── codestar.tf, codebuild.tf, codedeploy.tf, codepipeline.tf
│   ├── outputs.tf, userdata-backend.sh
│   └── terraform.tfvars.example
├── buildspec.yml                 # CodeBuild
├── appspec.yml                   # CodeDeploy
├── scripts/codedeploy/           # stop.sh, start.sh
└── README.md                     # This file (setup + reference)
```

---

## Core features

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

## Spring profiles (local vs AWS)

| Environment | Profile | Config |
|-------------|---------|--------|
| **Local** | *(none)* | `application.yml` — H2 |
| **AWS** | `stage` or `prod` | `application-stage.yml` / `application-prod.yml` — MySQL via `DB_*` env vars |

Terraform default is **`spring_profile = "stage"`**. Override in `terraform.tfvars` with `spring_profile = "prod"` for production.

---

## Quick start – local

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

## Local setup (detailed)

### Prerequisites

- **Java 17+** – [Adoptium](https://adoptium.net/) or Oracle JDK
- **Node.js 20+** – [nodejs.org](https://nodejs.org/)
- **Maven 3.9+** – [maven.apache.org](https://maven.apache.org/)

### 1. Start the backend

```bash
cd movie-booking-backend
mvn spring-boot:run
```

*(Maven wrapper: `./mvnw spring-boot:run`)*

- Backend: **http://localhost:8080**
- Uses **`application.yml` only** (no active profile) — **H2 in-memory** (no MySQL)
- To use MySQL locally, set **`SPRING_PROFILES_ACTIVE=stage`** or **`prod`** and set `DB_*` (see `application-stage.yml` / `application-prod.yml`)
- Seed data loads on startup (admin, john, sample movies/shows/seats)

**H2 console:** http://localhost:8080/h2-console — JDBC URL `jdbc:h2:mem:moviebookingdb`, user `sa`, password empty.

### 2. Start the frontend

```bash
cd movie-booking-frontend
npm install
npm run dev
```

- Frontend: **http://localhost:3000**
- Vite proxies `/api` → `http://localhost:8080`

### 3. Test the app

1. Open **http://localhost:3000**
2. Sign up or log in (`john` / `User@1234`)
3. Browse, pick a show, book seats (1–5)
4. Log in as **admin** for `/admin`

### Quick commands

| Task | Command |
|------|---------|
| Backend | `cd movie-booking-backend && mvn spring-boot:run` |
| Frontend | `cd movie-booking-frontend && npm run dev` |
| Backend tests | `cd movie-booking-backend && mvn test` |

### Troubleshooting (local)

| Issue | Fix |
|-------|-----|
| Port 8080 in use | Change `server.port` in `application.yml` or stop the other process |
| Port 3000 in use | Change port in `vite.config.js` |
| CORS errors | Backend running; CORS allows `http://localhost:3000` |
| Login fails | Restart backend (seed runs on startup) |

### What runs locally

- **Backend:** Spring Boot + H2
- **Frontend:** React + Vite
- **S3:** Disabled (`app.aws.enabled: false`) — placeholders for posters
- **AI:** In-JVM only, no external APIs

---

## AWS deployment (Terraform + CI/CD)

Deploy the app to AWS using Terraform. Uses **free-tier–eligible** shapes where possible and optional **CI/CD** (CodeBuild, CodeDeploy, CodePipeline).

### Architecture (AWS)

| Component | Service | Free tier (typical) |
|-----------|---------|----------------------|
| Backend | EC2 t2.micro | 750 hrs/month (12 mo) |
| Database | RDS MySQL db.t3.micro | 750 hrs/month, 20 GB (12 mo) |
| Frontend | S3 + CloudFront | S3 5 GB, CloudFront transfer (12 mo) |
| Posters | S3 | 5 GB total |
| CI/CD | CodeBuild, CodeDeploy, CodePipeline | Build minutes / pipeline promos |

**Flow:** One CloudFront — `/*` → S3, `/api/*` → EC2. **Pipeline:** GitHub → CodeBuild (JAR + frontend) → CodeDeploy (EC2) + S3 sync.

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) ≥ 1.5
- [AWS CLI](https://aws.amazon.com/cli/) (`aws configure`)
- Java 17, Maven, Node (for local builds / manual deploy)

### Step 1: Configure Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

- `db_username`, `db_password` — RDS
- `jwt_secret` — long random string (e.g. ≥ 32 chars)
- `ssh_public_key` — `cat ~/.ssh/id_rsa.pub`
- `github_repo`, `github_branch` — primary CodePipeline source branch
- `github_branch_secondary` — optional second branch (e.g. `stage`) that gets a **separate** pipeline name like `moviebook-pipeline-stage`. Leave `""` to disable. Each branch needs its own pipeline (AWS limit: one branch per Git source action).
- `spring_profile` — `stage` (default) or `prod`

**Optional:** store the whole `terraform.tfvars` in **AWS Secrets Manager** — see [Secrets Manager for `terraform.tfvars`](#secrets-manager-for-terraformtfvars).

### Step 2: Provision

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

RDS often takes 5–10 minutes. EC2 userdata waits for RDS.

### Step 3: Authorize GitHub (CI/CD)

1. AWS Console → **Developer Tools** → **Connections**
2. Find `{project_name}-github` (e.g. `moviebook-github`)
3. **Update pending connection** → complete GitHub OAuth

### Step 4: Deploy via pipeline

Push to the configured **primary** branch (`github_branch`) or, if set, the **secondary** branch (`github_branch_secondary`). Each enabled branch has its own pipeline; both use the same CodeBuild project, CodeDeploy application, and EC2 instance unless you change Terraform.

```bash
terraform -chdir=terraform output pipeline_url
terraform -chdir=terraform output pipeline_url_secondary   # non-null only if github_branch_secondary is set
```

### Manual deploy (fallback)

```bash
ART=$(terraform -chdir=terraform output -raw artifacts_bucket)
FE=$(terraform -chdir=terraform output -raw frontend_bucket)

cd movie-booking-backend && mvn package -DskipTests -q
aws s3 cp target/movie-booking-backend.jar "s3://$ART/movie-booking-backend.jar"

cd ../movie-booking-frontend && npm ci && VITE_API_BASE_URL=/api npm run build
aws s3 sync dist/ "s3://$FE/" --delete

# On EC2
sudo /opt/moviebooking/start.sh
```

### Seed data on AWS

Tables come from Hibernate / `schema-mysql.sql` as configured. Add users via **Signup** or SQL to `app_users` (bcrypt hashes).

### URLs after deploy

| Resource | How to get it |
|----------|----------------|
| App | `terraform -chdir=terraform output app_url` |
| SSH | `ssh -i key.pem ec2-user@<ec2-public-ip>` |

### Troubleshooting (AWS)

| Issue | Check |
|-------|--------|
| 502 from CloudFront | `curl http://<ec2-ip>:8080/actuator/health` |
| DB errors | RDS SG allows 3306 from EC2; private subnet |
| SPA 404 on refresh | CloudFront error pages → `index.html` |
| Blank UI | `VITE_API_BASE_URL=/api` for same-origin via CloudFront |

---

## Spring profile on EC2

- Terraform sets **`spring_profile`** (`stage` | `prod`); default in `variables.tf` is **`stage`**.
- Written to **`/opt/moviebooking/env`** as `SPRING_PROFILES_ACTIVE` (userdata). CodeBuild also receives it for logging.
- **`scripts/codedeploy/start.sh`** sources `env` and falls back to **`stage`** if unset.
- Changing profile for **existing** EC2: update `terraform.tfvars`, apply (may need **instance replace** so userdata rewrites `env`), or **edit `/opt/moviebooking/env`** and restart Java.

---

## AWS architecture (CloudFront, S3, RDS)

### Diagram

```
                    ┌─────────────────────────────────────────┐
                    │              USER BROWSER               │
                    │     https://xxxxx.cloudfront.net        │
                    └────────────────────┬────────────────────┘
                                         │
                                         ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                    CLOUDFRONT (single HTTPS entry)                          │
│   /*        → S3 (React SPA)          /api/*  → EC2:8080 (Spring Boot)     │
└─────────────┬──────────────────────────────────────┬───────────────────────┘
              │                                      │
              ▼                                      ▼
┌─────────────────────────┐            ┌─────────────────────────┐
│ S3 frontend bucket      │            │ EC2 (Spring Boot)       │
│ index.html, assets      │            │ JWT, bookings, admin    │
└─────────────────────────┘            └───────┬─────────┬─────────┘
                                               │         │
                                               ▼         ▼
                                    ┌──────────────┐  ┌─────────────┐
                                    │ RDS MySQL    │  │ S3 posters  │
                                    │ users, data  │  │ (private)   │
                                    └──────────────┘  └─────────────┘
```

### CloudFront

- One distribution: origins **S3** (static) and **EC2** (API).
- **HTTPS** with default CloudFront cert (`*.cloudfront.net`).
- SPA: 404/403 can map to `index.html` for client routing.
- **Why:** one origin for browser (no CORS pain for same-site `/api`), caching for static assets.

### S3 buckets (three roles)

| Bucket | Role |
|--------|------|
| **Frontend** | React build; only CloudFront reads (OAC). |
| **Artifacts** | Backend JAR; EC2 pulls via IAM role (`aws s3 cp`). |
| **Posters** | Admin uploads; users get **presigned URLs** from the API. |

### RDS MySQL

- Private subnets; SG allows **3306** only from EC2 SG.
- Spring: `jdbc:mysql://<host>:3306/...` with `DB_HOST`, `DB_USER`, `DB_PASSWORD` from EC2 env.

### Example flows

- **Open app:** `GET /` → CloudFront → S3 → `index.html` + static assets.
- **Login:** `POST /api/auth/login` → CloudFront → EC2 → RDS.
- **Poster image:** `GET /api/movies/{id}/poster-url` → presigned S3 URL → browser loads image from S3.

---

## AWS cost, free tier, destroy

### Stack (typical)

| Resource | Notes |
|----------|--------|
| EC2 t2.micro | ~750 hrs/mo free tier (new accounts, 12 mo) |
| RDS db.t3.micro | ~750 hrs + 20 GB storage (promo terms vary) |
| S3 | 3 buckets; 5 GB total on free tier |
| CloudFront | Transfer / request promos for 12 mo on new accounts |
| CodeBuild / Pipeline | Minute and pipeline promos |

**After free tier:** rough order of **~$25–35/mo** if instances run 24/7 (EC2 + RDS + transfer) — verify in **Cost Explorer**.

### Destroy

```bash
cd terraform
terraform destroy
# Non-interactive: terraform destroy -auto-approve
```

S3 may use `force_destroy`; RDS `skip_final_snapshot` may skip backups — check `rds.tf` before destroy in production.

### Billing alerts

1. **Billing** → **Budgets** → create monthly budget (e.g. $10–20) with alerts at 80% / 100%.
2. **Free Tier** / **Cost Explorer** for usage.

### Quick reference

| Task | Command |
|------|---------|
| Destroy | `cd terraform && terraform destroy` |
| Recreate | `cd terraform && terraform apply` |
| Outputs | `terraform output` |

---

## Secrets Manager for `terraform.tfvars`

Keep **real** `terraform.tfvars` **out of Git**. `terraform.tfvars.example` is the template only.

### Why

AWS Secrets Manager encrypts the secret (KMS). Fetch the file before `terraform plan/apply`, then delete locally if you want.

### One-time: create secret from file

From repo root, after filling `terraform/terraform.tfvars`:

```bash
export AWS_REGION=us-east-1
export SECRET_NAME="moviebook/terraform-tfvars"

aws secretsmanager create-secret \
  --region "$AWS_REGION" \
  --name "$SECRET_NAME" \
  --description "Terraform tfvars for moviebook (gitignored locally)" \
  --secret-string file://terraform/terraform.tfvars
```

Update later:

```bash
aws secretsmanager put-secret-value \
  --region "$AWS_REGION" \
  --secret-id "$SECRET_NAME" \
  --secret-string file://terraform/terraform.tfvars
```

### Before every `plan` / `apply`

```bash
aws secretsmanager get-secret-value \
  --region "$AWS_REGION" \
  --secret-id "$SECRET_NAME" \
  --query SecretString \
  --output text > terraform/terraform.tfvars

chmod 600 terraform/terraform.tfvars

cd terraform && terraform init && terraform plan
```

Optional: `rm -f terraform/terraform.tfvars` after apply.

### IAM

Principal needs at least:

- `secretsmanager:GetSecretValue` on the secret ARN
- `secretsmanager:PutSecretValue` / `CreateSecret` for uploads
- If using a **customer KMS key**: `kms:Decrypt` (and encrypt for puts)

**`AccessDeniedException` on `CreateSecret`:** attach **`SecretsManagerReadWrite`** (broader) or use least-privilege policy from **`terraform/iam-policy-secrets-manager-tfvars.json`** (see that file; attach to your IAM user).

### Console alternative

**Secrets Manager** → **Store a new secret** → **Other** → **Plaintext** → paste full `terraform.tfvars` → name e.g. `moviebook/terraform-tfvars` → store.

### Troubleshooting

| Symptom | Check |
|---------|--------|
| `GetSecretValue` denied | IAM policy; correct region; secret ARN |
| `kms:Decrypt` denied | CMK on secret — add decrypt |
| Terraform errors after download | Valid HCL; run `terraform validate` before uploading |

### Checklist

- [ ] `terraform.tfvars` gitignored and never committed
- [ ] Secret in correct **region**
- [ ] `chmod 600` after download
- [ ] Rotate RDS password in both Secrets Manager and AWS when changing DB password

---

## REST API reference

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

### Shows & seats

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
| GET | `/api/ai/recommendations` | User | Personalised movies |

### Admin (`ROLE_ADMIN`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/admin/movies` | Create movie + poster |
| PUT | `/api/admin/movies/{id}` | Update movie |
| DELETE | `/api/admin/movies/{id}` | Soft-delete movie |
| POST | `/api/admin/shows` | Create show |
| DELETE | `/api/admin/shows/{id}` | Soft-delete show |

---

## AI recommendation engine

Runs in the JVM — **no external APIs**, free-tier friendly.

**Strategy:** Genre affinity + popularity + rating boost; excludes already-watched titles. Each item can include a `reason` string.

---

## Security highlights

- BCrypt passwords (strength 12)
- JWT (24 h expiry, HMAC-SHA256)
- Secrets via env / Secrets Manager — not in source
- CORS restricted to CloudFront / localhost patterns
- RDS in private subnet
- S3 posters bucket private (presigned URLs)
