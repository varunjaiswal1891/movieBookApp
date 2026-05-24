#!/bin/bash
# CodeDeploy ValidateService – ensure app is up before deployment succeeds
set -euo pipefail

HEALTH_URL="http://127.0.0.1:8080/actuator/health"
MAX_RETRIES=30
SLEEP_SECONDS=2

for i in $(seq 1 "$MAX_RETRIES"); do
  if command -v curl >/dev/null 2>&1; then
    if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then
      echo "ValidateService passed: backend health endpoint is reachable."
      exit 0
    fi
  elif timeout 2 bash -c "cat < /dev/null > /dev/tcp/127.0.0.1/8080" >/dev/null 2>&1; then
    echo "ValidateService passed: backend health endpoint is reachable."
    exit 0
  fi

  echo "Waiting for backend health... attempt ${i}/${MAX_RETRIES}"
  sleep "$SLEEP_SECONDS"
done

echo "ValidateService failed: backend health endpoint not ready."
if [ -f /var/log/moviebooking.log ]; then
  echo "---- /var/log/moviebooking.log (tail) ----"
  tail -n 120 /var/log/moviebooking.log || true
fi
exit 1
