#!/bin/bash
# CodeDeploy ApplicationStop – stop the Spring Boot backend
set -e

APP_DIR=/opt/moviebooking
PID_FILE="$APP_DIR/app.pid"

if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  if kill -0 "$PID" 2>/dev/null; then
    echo "Stopping process $PID..."
    kill "$PID" || true
    for i in $(seq 1 10); do
      kill -0 "$PID" 2>/dev/null || break
      sleep 2
    done
    kill -9 "$PID" 2>/dev/null || true
  fi
  rm -f "$PID_FILE"
fi
echo "Application stopped"
