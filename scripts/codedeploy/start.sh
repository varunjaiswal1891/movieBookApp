#!/bin/bash
# CodeDeploy ApplicationStart – start Spring Boot from deployed JAR
# Env (DB_HOST, JWT_SECRET, etc.) is in /opt/moviebooking/env (created by EC2 userdata)
set -e

APP_DIR=/opt/moviebooking
cd "$APP_DIR"
source /opt/moviebooking/env

nohup java -jar -Dspring.profiles.active=prod "$APP_DIR/app.jar" \
  > /var/log/moviebooking.log 2>&1 &
echo $! > "$APP_DIR/app.pid"
echo "Backend started with PID $(cat $APP_DIR/app.pid)"
