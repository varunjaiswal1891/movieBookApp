#!/bin/bash
# Validate the application started successfully by polling the health endpoint
set -e

MAX_RETRIES=15
RETRY_INTERVAL=6
HEALTH_URL="http://localhost:8080/actuator/health"

echo "Waiting for application to become healthy..."
for i in $(seq 1 $MAX_RETRIES); do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" 2>/dev/null || echo "000")
    if [ "$STATUS" = "200" ]; then
        echo "Application is healthy (HTTP 200)."
        exit 0
    fi
    echo "Attempt $i/$MAX_RETRIES – HTTP $STATUS – retrying in ${RETRY_INTERVAL}s..."
    sleep "$RETRY_INTERVAL"
done

echo "Application did not become healthy in time."
exit 1
