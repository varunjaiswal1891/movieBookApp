#!/bin/bash
set -e
yum update -y
yum install -y java-17-amazon-corretto-headless nc

# Amazon Linux 2023: AWS CLI v2 is pre-installed
mkdir -p /opt/moviebooking
cd /opt/moviebooking

# Env file (Terraform substitutes variables before this script runs)
# Use single quotes for DB_PASSWORD and JWT_SECRET to prevent $ expansion in bash
cat > /opt/moviebooking/env << EOF
export SPRING_PROFILES_ACTIVE=prod
export DB_HOST="${db_host}"
export DB_PORT="${db_port}"
export DB_NAME="${db_name}"
export DB_USER="${db_user}"
export DB_PASSWORD='${replace(db_password, "'", "'\\''")}'
export JWT_SECRET='${replace(jwt_secret, "'", "'\\''")}'
export AWS_REGION="${aws_region}"
export S3_BUCKET="${posters_bucket}"
EOF

# Start script
cat > /opt/moviebooking/start.sh << 'STARTSCRIPT'
#!/bin/bash
set -e
cd /opt/moviebooking && source /opt/moviebooking/env
aws s3 cp s3://BUCKET_PLACEHOLDER/JAR_PLACEHOLDER app.jar --region $AWS_REGION || {
  echo "JAR not found. Run: ./scripts/deploy-backend.sh <artifacts-bucket>"
  exit 1
}
nohup java -jar -Dspring.profiles.active=prod app.jar > /var/log/moviebooking.log 2>&1 &
echo $! > /opt/moviebooking/app.pid
echo "Backend started"
STARTSCRIPT
sed -i "s|BUCKET_PLACEHOLDER|${artifacts_bucket}|g; s|JAR_PLACEHOLDER|${jar_key}|g" /opt/moviebooking/start.sh
chmod +x /opt/moviebooking/start.sh

# Wait for RDS
echo "Waiting for RDS..."
for i in $(seq 1 60); do
  if nc -z ${db_host} ${db_port} 2>/dev/null; then
    echo "RDS is ready"; break
  fi
  echo "Attempt $i: RDS not ready, retrying in 10s..."; sleep 10
done

# Try to start (JAR may not be uploaded yet – run start.sh manually after deploy-backend)
/opt/moviebooking/start.sh || echo "Upload JAR, then: sudo /opt/moviebooking/start.sh"
