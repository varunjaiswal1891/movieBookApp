#!/bin/bash
# Prepare the EC2 instance before deploying the new JAR
set -e

APP_DIR=/opt/moviebooking

echo "Installing Java 17 if not present..."
if ! java -version 2>&1 | grep -q "17"; then
    yum install -y java-17-amazon-corretto-headless 2>/dev/null \
    || apt-get install -y openjdk-17-jre-headless 2>/dev/null \
    || true
fi

echo "Ensuring app directory exists..."
mkdir -p "$APP_DIR"
chmod 750 "$APP_DIR"

# Create a dedicated service user if it doesn't exist
if ! id -u movieapp &>/dev/null; then
    useradd -r -s /sbin/nologin movieapp
fi

echo "Before-install complete."
