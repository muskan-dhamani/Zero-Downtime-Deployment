#!/bin/bash

IMAGE=$1
APP_NAME=jenkins-app
BLUE_PORT=8081
GREEN_PORT=8082

if [ -z "$IMAGE" ]; then
  echo "Image required"
  exit 1
fi

# Detect active color
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

# Run new container
docker run -d \
  --name ${APP_NAME}-${NEW_COLOR} \
  -p ${NEW_PORT}:80 \
  ${IMAGE}

if ! docker ps | grep -q "${APP_NAME}-${NEW_COLOR}"; then
  echo "Container failed to start"
  docker logs ${APP_NAME}-${NEW_COLOR} || true
  exit 1
fi

echo "Waiting for application to become healthy..."

MAX_RETRIES=10
SLEEP_TIME=5
COUNT=0

until curl -sf http://localhost:$NEW_PORT > /dev/null
do
  COUNT=$((COUNT+1))
  if [ "$COUNT" -ge "$MAX_RETRIES" ]; then
    echo "Health check failed after retries"
    docker logs ${APP_NAME}-${NEW_COLOR}
    docker rm -f ${APP_NAME}-${NEW_COLOR}
    exit 1
  fi
  echo "Retry $COUNT/$MAX_RETRIES..."
  sleep $SLEEP_TIME
done

echo "New container is healthy"

# Stop old container
docker rm -f ${APP_NAME}-${ACTIVE_COLOR} || true

echo "Switched traffic to ${NEW_COLOR}"

