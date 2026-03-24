# Detailed steps: AWS Secrets Manager for `terraform.tfvars`

Store the **entire contents** of `terraform.tfvars` as a **single secret** in **AWS Secrets Manager**. Before each `terraform apply` (or `plan`), download it to `terraform/terraform.tfvars` (or use environment variables only for sensitive keys — this guide uses the **whole file** approach).

**Why this works:** Secrets Manager encrypts the value at rest (AWS KMS). You never commit real values to Git; only `terraform.tfvars.example` stays in the repo.

---

## AWS CLI only — copy/paste flow

Set your region and secret name once (match `aws_region` in tfvars):

```bash
export AWS_REGION=us-east-1
export SECRET_NAME="moviebook/terraform-tfvars"
```

**1. Prepare local file (from repo root)**

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with real values, then:
terraform init
terraform validate
cd ..
```

**2. Create the secret (first time only)** — uploads the whole file as the secret string:

```bash
aws secretsmanager create-secret \
  --region "$AWS_REGION" \
  --name "$SECRET_NAME" \
  --description "Terraform tfvars for moviebook (gitignored locally)" \
  --secret-string file://terraform/terraform.tfvars
```

If you already created it and need to replace the value:

```bash
aws secretsmanager put-secret-value \
  --region "$AWS_REGION" \
  --secret-id "$SECRET_NAME" \
  --secret-string file://terraform/terraform.tfvars
```

**3. (Optional) Confirm the secret exists**

```bash
aws secretsmanager describe-secret \
  --region "$AWS_REGION" \
  --secret-id "$SECRET_NAME"
```

**4. Before `terraform plan` / `apply` — download to disk**

```bash
aws secretsmanager get-secret-value \
  --region "$AWS_REGION" \
  --secret-id "$SECRET_NAME" \
  --query SecretString \
  --output text > terraform/terraform.tfvars

chmod 600 terraform/terraform.tfvars
```

**5. Run Terraform**

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**6. (Optional) Remove local file after apply**

```bash
rm -f terraform/terraform.tfvars
```

**7. Update secret later (after editing a local tfvars file)**

```bash
aws secretsmanager put-secret-value \
  --region "$AWS_REGION" \
  --secret-id "$SECRET_NAME" \
  --secret-string file://terraform/terraform.tfvars
```

**IAM (CLI user running the above)** needs at least:

- `secretsmanager:CreateSecret` (first create only)
- `secretsmanager:GetSecretValue` (every fetch)
- `secretsmanager:PutSecretValue` (updates)
- `secretsmanager:DescribeSecret` (optional describe)

If the secret uses a **customer managed KMS key**, add `kms:Decrypt` (and `kms:Encrypt` for put) on that key.

### `AccessDeniedException` on `CreateSecret`

Your IAM user must be allowed to call `secretsmanager:CreateSecret`. If you see:

`User: ... is not authorized to perform: secretsmanager:CreateSecret`

**Option A — AWS managed (broader):** attach **`SecretsManagerReadWrite`** to your user (IAM → Users → your user → Add permissions → attach policy).

**Option B — Least privilege (this repo):** create a customer policy from **`terraform/iam-policy-secrets-manager-tfvars.json`**, then attach it to your user (account admin runs):

```bash
ACCOUNT_ID=149536493115   # your account
POLICY_NAME="MovieBookAppSecretsManagerTfvars"

aws iam create-policy \
  --policy-name "$POLICY_NAME" \
  --policy-document file://terraform/iam-policy-secrets-manager-tfvars.json

aws iam attach-user-policy \
  --user-name varunIamUser1 \
  --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"
```

If `create-policy` says the policy already exists, only run `attach-user-policy` using the existing policy ARN from IAM.

Then retry `aws secretsmanager create-secret ...`.

---

## Prerequisites

1. **AWS account** and **region** where you run Terraform (e.g. `us-east-1`).
2. **AWS CLI** installed and configured (`aws configure` or SSO) so you can call Secrets Manager.
3. **IAM permission** to create secrets (first-time setup) and **get secret values** (every time you run Terraform).
4. A local **template** from the repo: `terraform/terraform.tfvars.example` → copy to `terraform/terraform.tfvars` and fill real values **once** on a secure machine.

---

## Part A — Prepare the file content (once, on your laptop)

1. From the project root:

   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with real values:

   - `db_password`, `jwt_secret`, `ssh_public_key`, `github_branch`, `artifacts_upload_iam_arns` (if used), etc.
   - Use valid HCL: strings in double quotes, booleans `true`/`false`, lists `[...]`.

3. **Do not commit** this file. Confirm it is ignored:

   ```bash
   git check-ignore -v terraform/terraform.tfvars
   ```

   You should see an entry from `.gitignore`.

4. **Optional:** Validate syntax with Terraform (no apply):

   ```bash
   cd terraform
   terraform init
   terraform validate
   ```

   Fix any errors before uploading the secret.

---

## Part B — Create the secret in AWS Secrets Manager

### Option 1 — AWS Console (click-through)

1. Sign in to **AWS Console** → select the **same region** as `aws_region` in your tfvars (e.g. **N. Virginia** for `us-east-1`).
2. Open **Secrets Manager** (search “Secrets Manager”).
3. Click **Store a new secret**.
4. **Secret type:** choose **Other type of secret**.
5. **Key/value pairs:** leave default; we will use **Plaintext** instead.

   - Switch to **Plaintext** tab, or choose **Plaintext** if available.

6. **Paste the entire contents** of your local `terraform/terraform.tfvars` file into the text box (including comments if you like; HCL is fine).

7. Click **Next**.

8. **Secret name:** use a clear name, e.g. `moviebook/terraform-tfvars` (must be unique in the account/region).

9. **Optional:** Description, tags, **Rotation** — leave rotation off unless you have a custom rotation Lambda (not required for static tfvars).

10. **Encryption key:** default **aws/secretsmanager** is fine for most cases; use a **customer managed KMS key** if your org requires it (then grant `kms:Decrypt` to users who read the secret).

11. Click **Next** → review → **Store**.

12. Copy the **Secret ARN** from the secret details page (you’ll need it for IAM policies).

### Option 2 — AWS CLI (one command)

From your project root, **after** `terraform/terraform.tfvars` is filled and saved:

```bash
# Replace region if needed
export AWS_REGION=us-east-1
export SECRET_NAME="moviebook/terraform-tfvars"

aws secretsmanager create-secret \
  --name "$SECRET_NAME" \
  --description "MovieBook Terraform tfvars (do not commit)" \
  --secret-string file://terraform/terraform.tfvars \
  --region "$AWS_REGION"
```

If the secret **already exists**, update it instead:

```bash
aws secretsmanager put-secret-value \
  --secret-id "$SECRET_NAME" \
  --secret-string file://terraform/terraform.tfvars \
  --region "$AWS_REGION"
```

---

## Part C — IAM: who may read the secret?

The principal that runs `terraform` (your IAM user, role, or CI role) needs:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue"],
      "Resource": "arn:aws:secretsmanager:us-east-1:YOUR_ACCOUNT_ID:secret:moviebook/terraform-tfvars-XXXXXX"
    }
  ]
}
```

- Replace `YOUR_ACCOUNT_ID` and the **full secret ARN** (suffix may include a random `-AbCdEf` — use the ARN from the console).
- If the secret uses a **customer managed KMS key**, add:

```json
{
  "Effect": "Allow",
  "Action": ["kms:Decrypt"],
  "Resource": "arn:aws:kms:us-east-1:YOUR_ACCOUNT_ID:key/KEY-ID"
}
```

Attach this policy to your **IAM user** (e.g. `varunIamUser1`) or to the **role** used by CI.

**First-time secret creation** also needs `secretsmanager:CreateSecret` (only on the admin account that creates the secret once).

---

## Part D — Download the secret before `terraform apply`

### Method 1 — One-line AWS CLI

```bash
cd /path/to/movieBookApp/terraform

aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --query SecretString \
  --output text > terraform.tfvars

chmod 600 terraform.tfvars
```

Set `SECRET_NAME` to the name you used (e.g. `moviebook/terraform-tfvars`).

### Method 2 — Helper script (repo)

From **project root**:

```bash
export TFVARS_SECRET_ID=moviebook/terraform-tfvars
./scripts/fetch-tfvars-from-aws.sh
# or: ./scripts/fetch-tfvars-from-aws.sh moviebook/terraform-tfvars
```

This writes `terraform/terraform.tfvars` and sets file mode `600`.

### Method 3 — CI (e.g. GitHub Actions)

In a job step (after assuming AWS role via OIDC):

```bash
aws secretsmanager get-secret-value \
  --secret-id moviebook/terraform-tfvars \
  --query SecretString \
  --output text > terraform/terraform.tfvars
```

Do **not** print `terraform.tfvars` or secret values in logs.

---

## Part E — Run Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

When finished, you can **delete the local file** if you want nothing on disk:

```bash
shred -u terraform.tfvars 2>/dev/null || rm -f terraform.tfvars
```

(Next run, fetch from Secrets Manager again.)

---

## Updating values (password rotation, new SSH key, etc.)

1. Edit **local** `terraform/terraform.tfvars` (or use `aws secretsmanager get-secret-value` → edit → `put-secret-value`), or edit in **Secrets Manager** console (“Retrieve secret value” → **Edit**).

2. **CLI update from file:**

   ```bash
   aws secretsmanager put-secret-value \
     --secret-id moviebook/terraform-tfvars \
     --secret-string file://terraform/terraform.tfvars
   ```

3. If you changed **RDS master password** in tfvars, also **change the password in RDS** (or apply Terraform so RDS updates) so the database and tfvars stay in sync.

---

## Troubleshooting

| Symptom | What to check |
|--------|----------------|
| `AccessDeniedException` on `GetSecretValue` | IAM policy on your user/role; secret ARN; correct region in CLI. |
| `kms:Decrypt` denied | Secret uses CMK; add `kms:Decrypt` for that key. |
| Terraform errors after download | Bad HCL in secret (quotes, commas); `terraform validate` locally before `put-secret-value`. |
| Wrong region | Secret must exist in the **same region** as `aws configure` / `AWS_REGION`. |

---

## Checklist

- [ ] `terraform.tfvars` is **never** committed (gitignored).
- [ ] Secret created in **correct** region.
- [ ] IAM allows **GetSecretValue** (and **kms:Decrypt** if needed).
- [ ] `chmod 600 terraform.tfvars` after download.
- [ ] Rotate secrets in Secrets Manager and in AWS resources (RDS, etc.) together when passwords change.
