#!/bin/bash
set -eo pipefail

IMAGE_NAME=$1

if [ -z "$IMAGE_NAME" ]; then
  echo "Error: IMAGE_NAME is required for Trivy scan."
  exit 1
fi

echo "=== Running Trivy Security Vulnerability Scan on ${IMAGE_NAME} ==="
trivy image \
  --severity HIGH,CRITICAL \
  --exit-code 0 \
  --light \
  "$IMAGE_NAME"

echo "Trivy Scan completed successfully for ${IMAGE_NAME}."
