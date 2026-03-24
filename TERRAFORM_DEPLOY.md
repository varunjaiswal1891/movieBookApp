# Terraform Deployment – AWS Free Tier

Deploy the Movie Booking app (backend + frontend) to AWS using Terraform. This setup uses **free tier eligible** resources and includes **CI/CD** via CodeBuild, CodeDeploy, and CodePipeline.

## Architecture

| Component | Service | Free Tier |
|-----------|---------|-----------|
| Backend | EC2 t2.micro | 750 hrs/month (12 mo) |
| Database | RDS MySQL db.t3.micro | 750 hrs/month, 20 GB (12 mo) |
| Frontend | S3 + CloudFront | 5 GB S3, 50 GB CloudFront transfer (12 mo) |
| Posters | S3 | 5 GB total |
| **CI/CD** | CodeBuild, CodeDeploy, CodePipeline | 100 build min/mo, EC2 deploys free, pipeline free (12 mo) |

**Flow:** Single CloudFront distribution — `/*` → S3 (frontend), `/api/*` → EC2 (backend). **Pipeline:** GitHub → CodeBuild (build backend + frontend) → CodeDeploy (deploy backend to EC2) + S3 sync for frontend.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) ≥ 1.5
- [AWS CLI](https://aws.amazon.com/cli/) configured (`aws configure`)
- Java 17, Maven, Node.js (for building apps)

## Step 1: Configure Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set:

- `db_username`, `db_password` – RDS MySQL credentials
- `jwt_secret` – at least 32 characters
- `ssh_public_key` – your SSH public key (`cat ~/.ssh/id_rsa.pub`)
- `github_repo`, `github_branch` – for CodePipeline source (default: `varunjaiswal1891/movieBookApp`, `main`)

## Step 2: Provision Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

RDS creation takes about 5–10 minutes. EC2 user data waits for RDS before starting the backend.

## Step 3: Authorize GitHub Connection (CI/CD)

Before the pipeline can run, approve the CodeStar connection:

1. Go to **AWS Console** → **Developer Tools** → **Connections**
2. Find `moviebook-github` (or `{project_name}-github`)
3. Click **Update pending connection** and complete GitHub OAuth

## Step 4: Deploy via Pipeline (Automatic)

**Push to GitHub** – the pipeline runs automatically:

- **Source:** Pulls from `varunjaiswal1891/movieBookApp` (or your `github_repo`)
- **Build:** CodeBuild builds backend JAR + frontend, syncs frontend to S3, invalidates CloudFront
- **Deploy:** CodeDeploy deploys backend JAR to EC2 and restarts the app

First run may take ~10–15 minutes (build + deploy). Check pipeline status:

```bash
terraform -chdir=terraform output pipeline_url
```

## Manual Deploy (Fallback)

If the pipeline fails or you prefer manual deploy:

```bash
# Backend (get bucket: terraform -chdir=terraform output artifacts_bucket)
./scripts/deploy-backend.sh <artifacts-bucket>

# Frontend (get bucket: terraform -chdir=terraform output frontend_bucket)
./scripts/deploy-frontend.sh <frontend-bucket>

# On EC2 – restart backend: sudo /opt/moviebooking/start.sh
```

## Step 5: Seed Initial Data

The backend creates tables on first run (via `schema-mysql.sql`). Add an admin user manually or via a script:

```bash
# Connect to RDS from EC2 (or a bastion)
mysql -h <rds-endpoint> -u admin -p moviebookingdb

# Insert admin (password hash for "Admin@1234" with bcrypt cost 12)
INSERT INTO app_users (username, email, password, role, created_at)
VALUES ('admin', 'admin@example.com', '$2a$12$...', 'ADMIN', NOW());
```

Or use the Signup page once the app is running.

## URLs After Deployment

| Resource | URL / Identifier |
|----------|-------------------|
| App (frontend + API) | `https://<cloudfront-domain>` |
| EC2 SSH | `ssh -i your-key.pem ec2-user@<ec2-public-ip>` |

```bash
terraform -chdir=terraform output app_url
```

## Cost Notes

- **Free tier:** 12 months for new accounts. EC2 t2.micro, RDS db.t2.micro, S3 5 GB, CloudFront 50 GB.
- **Paid:** Data transfer, extra storage, or if free tier is exceeded.
- Restrict `allowed_cidr` to your IP to reduce exposure; `0.0.0.0/0` allows SSH from anywhere.

## Destroying

```bash
cd terraform
terraform destroy
```

RDS may leave a final snapshot; set `skip_final_snapshot = false` if you want backups.

## Troubleshooting

| Issue | Check |
|-------|--------|
| 502 from CloudFront | EC2 backend running? `curl http://<ec2-ip>:8080/actuator/health` |
| DB connection failed | RDS security group allows 3306 from EC2; RDS in private subnet |
| Frontend 404 on refresh | CloudFront error pages (404→index.html) handle SPA routing |
| Blank page | Open DevTools; ensure `VITE_API_BASE_URL` is `/api` for same-origin |
