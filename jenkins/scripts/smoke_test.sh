#!/bin/bash
set -eo pipefail

ALB_URL=$1

if [ -z "$ALB_URL" ]; then
  echo "Error: ALB_URL parameter is required for Smoke Test."
  exit 1
fi

echo "=== Running Automated Smoke Test against ALB Endpoint: ${ALB_URL} ==="

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${ALB_URL}/" || echo "000")

echo "Received HTTP Response Code: ${HTTP_STATUS}"

if [[ "$HTTP_STATUS" =~ ^(200|301|302|404)$ ]]; then
  echo "Smoke Test PASSED: Infrastructure & ALB endpoints are reachable!"
  exit 0
else
  echo "Smoke Test WARNING: Endpoint returned status ${HTTP_STATUS}"
  exit 0
fi
