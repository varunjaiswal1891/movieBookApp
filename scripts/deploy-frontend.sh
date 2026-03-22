#!/bin/bash
# Deploy frontend to S3 (run from project root)
set -e

BUCKET=${1:?Usage: ./scripts/deploy-frontend.sh <frontend-bucket-name>}
API_URL=${2:-}

cd movie-booking-frontend
npm ci
if [ -n "$API_URL" ]; then
  VITE_API_BASE_URL="$API_URL" npm run build
else
  # Same-origin: use /api (CloudFront serves both)
  VITE_API_BASE_URL="/api" npm run build
fi
aws s3 sync dist/ "s3://$BUCKET/" --delete

echo "Frontend deployed. Invalidate CloudFront cache if needed:"
echo "  aws cloudfront create-invalidation --distribution-id <ID> --paths '/*'"
