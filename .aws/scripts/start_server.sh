#!/bin/bash
# Start the Spring Boot application.
# Secrets are read from AWS SSM Parameter Store via the EC2 instance profile.
set -e

APP_DIR=/opt/moviebooking
APP_JAR="$APP_DIR/movie-booking-backend.jar"
APP_PID_FILE="$APP_DIR/app.pid"
LOG_FILE="$APP_DIR/app.log"

# ── Resolve secrets from SSM (requires ec2 instance role with ssm:GetParameter) ──
get_param() {
    aws ssm get-parameter --name "$1" --with-decryption --query "Parameter.Value" --output text
}

export DB_HOST=$(get_param /moviebooking/prod/db-host)
export DB_PORT=$(get_param /moviebooking/prod/db-port)
export DB_NAME=$(get_param /moviebooking/prod/db-name)
export DB_USER=$(get_param /moviebooking/prod/db-user)
export DB_PASSWORD=$(get_param /moviebooking/prod/db-password)
export JWT_SECRET=$(get_param /moviebooking/prod/jwt-secret)
export S3_BUCKET=$(get_param /moviebooking/prod/s3-bucket)
export AWS_REGION=$(get_param /moviebooking/prod/aws-region)

echo "Starting application..."
nohup sudo -u movieapp java \
    -jar "$APP_JAR" \
    --spring.profiles.active=prod \
    > "$LOG_FILE" 2>&1 &

echo $! > "$APP_PID_FILE"
echo "Application started with PID $(cat $APP_PID_FILE)"
