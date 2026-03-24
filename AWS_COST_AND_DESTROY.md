# AWS Cost, Free Tier & Destroy Guide

## Your Terraform Stack Resources

| Resource | Type | Free Tier | Usage |
|----------|------|-----------|-------|
| EC2 | t2.micro | 750 hrs/month | 24/7 = ~720 hrs |
| RDS MySQL | db.t3.micro | 750 hrs/month | 24/7 = ~720 hrs |
| S3 | 3 buckets | 5 GB total | Frontend + posters + artifacts |
| CloudFront | 1 distribution | 50 GB transfer / 2M requests | First 12 months |
| CodeBuild | 1 project | 100 build min/month | Free tier |
| CodePipeline | 1 pipeline | Free | First 12 months |
| CodeDeploy | EC2 deployments | Free | Always free for EC2 |
| VPC, EBS | — | Included with EC2 | — |
| Data transfer | — | 15 GB out (free tier) | After that: ~$0.09/GB |

---

## Free Tier Limits (12‑Month Accounts)

*If your account was created before July 15, 2025:*

| Service | Free Tier | Duration |
|---------|-----------|----------|
| EC2 t2.micro | 750 hours/month | 12 months |
| RDS db.t3.micro | 750 hours/month + 20 GB storage | 12 months |
| S3 | 5 GB storage | 12 months |
| CloudFront | 50 GB data transfer, 2M requests | 12 months |
| Data transfer out | 15 GB/month to internet | 12 months |

**Single instance running 24/7:**  
- EC2: 720–744 hrs/month → within 750 hrs  
- RDS: 720–744 hrs/month → within 750 hrs  

So your stack can stay **within free tier** if it runs continuously on these instance types for 12 months.

---

## Approximate Cost (After Free Tier)

| Resource | Approx. Monthly Cost | Notes |
|----------|----------------------|-------|
| EC2 t2.micro | ~$8–9 | ~$0.0116/hr × 720 hrs |
| RDS db.t3.micro | ~$15–20 | Instance + 20 GB storage |
| S3 | ~$0.23/GB | After 5 GB |
| CloudFront | ~$0.085/GB | After 50 GB |
| **Total (est.)** | **~$25–35/month** | If everything exceeds free tier |

---

## How to Destroy All Infrastructure

```bash
cd terraform
terraform destroy
```

- Terraform will list resources and ask for confirmation.
- Approve with `yes`.
- S3 buckets have `force_destroy = true`, so they will be emptied and deleted.
- RDS has `skip_final_snapshot = true`, so no manual snapshot is taken.

**Optional non‑interactive destroy:**
```bash
terraform destroy -auto-approve
```

---

## Billing Alerts & Usage Thresholds

### 1. Budget Alert in AWS

1. AWS Console → **Billing and Cost Management** → **Budgets**
2. **Create budget** → **Cost budget**
3. Set amount (e.g. **$10** or **$20**) and period (monthly)
4. Add alerts:
   - 80% of budget
   - 100% of budget
   - 120% of budget (optional)
5. Email for notifications
6. Save

### 2. Free Tier Usage (Cost Explorer)

1. **Billing and Cost Management** → **Free Tier**
2. See free tier usage per service.

### 3. Cost Explorer

1. **Cost Explorer** → enable if needed (wait 24 hours for data)
2. View spend by service and time range

---

## Recommended Actions

1. **Create a $10 or $20 budget** with alerts at 80% and 100%.
2. **Destroy when not in use**:
   ```bash
   terraform destroy
   ```
3. **Check Billing Dashboard** regularly.
4. **Re‑create later**:
   ```bash
   terraform apply
   ```

---

## Quick Reference

| Task | Command |
|------|---------|
| Destroy everything | `cd terraform && terraform destroy` |
| Re‑create stack | `cd terraform && terraform apply` |
| View outputs | `terraform output` |
| Budget setup | AWS Console → Billing → Budgets |
