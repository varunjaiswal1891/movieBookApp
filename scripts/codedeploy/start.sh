#!/bin/bash
# CodeDeploy ApplicationStart – start Spring Boot from deployed JAR
# SPRING_PROFILES_ACTIVE (stage|prod) is set in /opt/moviebooking/env (userdata)
set -e

APP_DIR=/opt/moviebooking
cd "$APP_DIR"
source /opt/moviebooking/env

export SPRING_PROFILES_ACTIVE="${SPRING_PROFILES_ACTIVE:-stage}"

nohup java -jar "$APP_DIR/app.jar" \
  > /var/log/moviebooking.log 2>&1 &
echo $! > "$APP_DIR/app.pid"
echo "Backend started (profile=$SPRING_PROFILES_ACTIVE) PID $(cat $APP_DIR/app.pid)"
