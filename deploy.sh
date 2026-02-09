#!/bin/bash

IMAGE=$1
APP_NAME=jenkins-app
BLUE_PORT=8081
GREEN_PORT=8082

if [ -z "$IMAGE" ]; then
  echo "Image required"
  exit 1
fi

# Detect which color is running
if docker ps --format '{{.Names}}' | grep -q "${APP_NAME}-blue"; then
  ACTIVE_COLOR="blue"
  ACTIVE_PORT=$BLUE_PORT
  NEW_COLOR="green"
  NEW_PORT=$GREEN_PORT
else
  ACTIVE_COLOR="green"
  ACTIVE_PORT=$GREEN_PORT
  NEW_COLOR="blue"
  NEW_PORT=$BLUE_PORT
fi

echo "Active: $ACTIVE_COLOR on port $ACTIVE_PORT"
echo "Deploying: $NEW_COLOR on port $NEW_PORT"

# Start new container
docker run -d \
  --name ${APP_NAME}-${NEW_COLOR} \
  -p ${NEW_PORT}:80 \
  ${IMAGE}

# Simple health check
sleep 5
if ! curl -f http://localhost:${NEW_PORT}; then
  echo "New container failed health check"
  docker rm -f ${APP_NAME}-${NEW_COLOR}
  exit 1
fi

# Stop old container
docker rm -f ${APP_NAME}-${ACTIVE_COLOR} || true

echo "Switched traffic to ${NEW_COLOR}"
