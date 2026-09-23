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

RDS_SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "rds!db-cd73dfc2-1804-4a7c-be28-7fa251cdbce0" --region "${AWS_REGION}" --query "SecretString" --output text 2>/dev/null || true)

if [ -n "$RDS_SECRET_JSON" ]; then
  DB_USER_VAL=$(echo "$RDS_SECRET_JSON" | grep -o '"username":"[^"]*' | cut -d'"' -f4)
  DB_PASS_VAL=$(echo "$RDS_SECRET_JSON" | grep -o '"password":"[^"]*' | cut -d'"' -f4)
else
  DB_USER_VAL="${CRM_DB_USER:-crm_admin}"
  DB_PASS_VAL="${CRM_DB_PASSWORD:-?21NVK[Yj?BDX~8XzGqZ<]TcMNrm}"
fi

echo "=== Ensuring Kubernetes Secret crm-db-secret in namespace ${K8S_NAMESPACE} ==="
kubectl create secret generic crm-db-secret \
  --from-literal=DB_USER="${DB_USER_VAL}" \
  --from-literal=DB_PASSWORD="${DB_PASS_VAL}" \
  -n "${K8S_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

IFS=',' read -ra SERVICES <<< "$SERVICES_LIST"

HELM_SET_ARGS=("--set" "global.imageRegistry=${ECR_REGISTRY}" "--set" "environment=test")

for svc in "${SERVICES[@]}"; do
  SVC_KEY="${svc%-service}"
  HELM_SET_ARGS+=("--set" "services.${SVC_KEY}.image=speshway-test-${svc}")
  HELM_SET_ARGS+=("--set" "services.${SVC_KEY}.tag=${IMAGE_TAG}")
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

VALUES_FILE="${REPO_DIR}/jenkins/values-test.yaml"
if [ -f "${REPO_DIR}/helm/crm/values-test.yaml" ]; then
  VALUES_FILE="${REPO_DIR}/helm/crm/values-test.yaml"
fi

echo "=== Upgrading Helm Chart 'crm' in namespace ${K8S_NAMESPACE} ==="
helm upgrade --install crm "${REPO_DIR}/helm/crm" \
  --namespace "${K8S_NAMESPACE}" \
  "${HELM_SET_ARGS[@]}" \
  -f "${VALUES_FILE}"

echo "Helm deployment completed successfully."
