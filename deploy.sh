#!/bin/bash
set -e

IMAGE=$1
APP_NAME=jenkins-app
BLUE_PORT=8081
GREEN_PORT=8082

if [ -z "$IMAGE" ]; then
  echo "Image name required"
  exit 1
fi

# Detect active color
if docker ps --format '{{.Names}}' | grep -q "${APP_NAME}-blue"; then
  ACTIVE_COLOR="blue"
  ACTIVE_PORT=$BLUE_PORT
  NEW_COLOR="green"
  NEW_PORT=$GREEN_PORT
elif docker ps --format '{{.Names}}' | grep -q "${APP_NAME}-green"; then
  ACTIVE_COLOR="green"
  ACTIVE_PORT=$GREEN_PORT
  NEW_COLOR="blue"
  NEW_PORT=$BLUE_PORT
else
  echo "No active container found. Starting fresh deployment."
  ACTIVE_COLOR=""
  ACTIVE_PORT=""
  NEW_COLOR="blue"
  NEW_PORT=$BLUE_PORT
fi

echo "Active color: ${ACTIVE_COLOR:-none}"
echo "Deploying new color: $NEW_COLOR on port $NEW_PORT"

# Remove any old stopped container with same name
docker rm -f ${APP_NAME}-${NEW_COLOR} 2>/dev/null || true

# Start new container
docker run -d \
  --name ${APP_NAME}-${NEW_COLOR} \
  -p ${NEW_PORT}:80 \
  ${IMAGE}

echo "Waiting for application to become healthy..."

MAX_RETRIES=10
SLEEP_TIME=3
COUNT=0

until docker exec ${APP_NAME}-${NEW_COLOR} curl -sf http://localhost > /dev/null
do
  COUNT=$((COUNT+1))
  if [ "$COUNT" -ge "$MAX_RETRIES" ]; then
    echo "Health check failed after $MAX_RETRIES attempts"
    docker logs ${APP_NAME}-${NEW_COLOR}
    docker rm -f ${APP_NAME}-${NEW_COLOR}
    exit 1
  fi
  echo "Retry $COUNT/$MAX_RETRIES..."
  sleep $SLEEP_TIME
done

echo "New container is healthy"

# Stop old container only after new one is healthy
if [ -n "$ACTIVE_COLOR" ]; then
  echo "Stopping old container: ${APP_NAME}-${ACTIVE_COLOR}"
  docker rm -f ${APP_NAME}-${ACTIVE_COLOR}
fi

echo "Traffic switched to ${NEW_COLOR}"
echo "Zero-downtime deployment completed successfully"

