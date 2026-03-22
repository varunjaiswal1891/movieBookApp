#!/bin/bash
# Stop the Spring Boot app if it is running
set -e

APP_PID_FILE=/opt/moviebooking/app.pid

if [ -f "$APP_PID_FILE" ]; then
    PID=$(cat "$APP_PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "Stopping application (PID $PID)..."
        kill -SIGTERM "$PID"
        sleep 5
        kill -0 "$PID" 2>/dev/null && kill -SIGKILL "$PID" || true
    fi
    rm -f "$APP_PID_FILE"
fi

echo "Application stopped."
