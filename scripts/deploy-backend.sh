#!/bin/bash
# Build and upload backend JAR to S3 (run from project root)
set -e

BUCKET=${1:?Usage: ./scripts/deploy-backend.sh <artifacts-bucket-name>}
KEY=${2:-movie-booking-backend.jar}

cd movie-booking-backend
mvn package -DskipTests -q
aws s3 cp target/movie-booking-backend.jar "s3://$BUCKET/$KEY"

echo "Backend JAR uploaded. Restart EC2 or re-run user data to pick up the new JAR."
