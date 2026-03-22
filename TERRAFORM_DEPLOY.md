# Terraform Deployment – AWS Free Tier

Deploy the Movie Booking app (backend + frontend) to AWS using Terraform. This setup uses **free tier eligible** resources where possible.

## Architecture

| Component | Service | Free Tier |
|-----------|---------|-----------|
| Backend | EC2 t2.micro | 750 hrs/month (12 mo) |
| Database | RDS MySQL db.t2.micro | 750 hrs/month, 20 GB (12 mo) |
| Frontend | S3 + CloudFront | 5 GB S3, 50 GB CloudFront transfer (12 mo) |
| Posters | S3 | 5 GB total |

**Flow:** Single CloudFront distribution — `/*` → S3 (frontend), `/api/*` → EC2 (backend). Frontend and API share the same origin, so no CORS issues.

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

## Step 2: Provision Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

RDS creation takes about 5–10 minutes. EC2 user data waits for RDS before starting the backend.

## Step 3: Deploy Backend JAR

Build and upload the backend JAR to S3:

```bash
# From project root (get bucket from: terraform -chdir=terraform output artifacts_bucket)
./scripts/deploy-backend.sh <artifacts-bucket>
```

EC2 user data runs on first boot and tries to download the JAR. If you run `deploy-backend.sh` *before* `terraform apply`, the JAR will be present and the backend should start automatically. Otherwise, after uploading:

```bash
# SSH (use key matching ssh_public_key and EC2 IP from: terraform output backend_ec2_public_ip)
ssh -i your-key.pem ec2-user@<ec2-public-ip>

# On EC2 – start or restart backend
sudo /opt/moviebooking/start.sh
```

## Step 4: Deploy Frontend

Build and upload the frontend to S3:

```bash
# From project root
./scripts/deploy-frontend.sh <frontend-bucket>
```

Get the bucket name:

```bash
terraform -chdir=terraform output frontend_bucket
```

For same-origin (recommended), the script uses `VITE_API_BASE_URL=/api` so the frontend calls the CloudFront URL with `/api`, which proxies to the backend.

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
