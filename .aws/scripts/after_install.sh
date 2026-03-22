#!/bin/bash
# Post-install: set permissions and make scripts executable
set -e

APP_DIR=/opt/moviebooking

chown -R movieapp:movieapp "$APP_DIR"
chmod +x "$APP_DIR"/scripts/*.sh
chmod 640 "$APP_DIR"/*.jar

echo "After-install complete."
