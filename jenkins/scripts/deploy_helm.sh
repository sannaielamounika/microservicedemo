#!/bin/bash
set -eo pipefail

AWS_REGION=$1
EKS_CLUSTER_NAME=$2
K8S_NAMESPACE=$3
ECR_REGISTRY=$4
IMAGE_TAG=$5
SERVICES_LIST=$6

echo "=== Updating kubeconfig for EKS Cluster: ${EKS_CLUSTER_NAME} in ${AWS_REGION} ==="
aws eks update-kubeconfig --region "${AWS_REGION}" --name "${EKS_CLUSTER_NAME}"
kubectl create namespace "${K8S_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

IFS=',' read -ra SERVICES <<< "$SERVICES_LIST"

for svc in "${SERVICES[@]}"; do
  echo "=== Upgrading Helm Chart for ${svc} in namespace ${K8S_NAMESPACE} ==="
  
  if [ -d "./helm/${svc}" ]; then
    CHART_PATH="./helm/${svc}"
  elif [ -d "./helm/crm" ]; then
    CHART_PATH="./helm/crm"
  else
    CHART_PATH="./helm"
  fi

  if [ -f "./helm/${svc}/values-test.yaml" ]; then
    VALUES_FILE="./helm/${svc}/values-test.yaml"
  elif [ -f "./helm/crm/values-test.yaml" ]; then
    VALUES_FILE="./helm/crm/values-test.yaml"
  else
    VALUES_FILE="jenkins/values-test.yaml"
  fi

  helm upgrade --install "${svc}" "${CHART_PATH}" \
    --namespace "${K8S_NAMESPACE}" \
    --set image.repository="${ECR_REGISTRY}/speshway-test-${svc}" \
    --set image.tag="${IMAGE_TAG}" \
    --set environment=test \
    -f "${VALUES_FILE}" \
    --wait \
    --timeout 5m
done

echo "Helm deployment completed successfully."
