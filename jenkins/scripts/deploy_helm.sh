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

kubectl create secret generic crm-db-secret \
  --from-literal=DB_USER=crm_admin \
  --from-literal='DB_PASSWORD=FbH(L29w]1t*L<Zy(T|->Uv1!8E2' \
  -n "${K8S_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

IFS=',' read -ra SERVICES <<< "$SERVICES_LIST"

HELM_SET_ARGS=("--set" "global.imageRegistry=${ECR_REGISTRY}" "--set" "environment=test")

for svc in "${SERVICES[@]}"; do
  SVC_KEY="${svc%-service}"
  HELM_SET_ARGS+=("--set" "services.${SVC_KEY}.image=speshway-test-${svc}")
  HELM_SET_ARGS+=("--set" "services.${SVC_KEY}.tag=${IMAGE_TAG}")
done

VALUES_FILE="jenkins/values-test.yaml"
if [ -f "./helm/crm/values-test.yaml" ]; then
  VALUES_FILE="./helm/crm/values-test.yaml"
fi

echo "=== Upgrading Helm Chart 'crm' in namespace ${K8S_NAMESPACE} ==="
helm upgrade --install crm ./helm/crm \
  --namespace "${K8S_NAMESPACE}" \
  "${HELM_SET_ARGS[@]}" \
  -f "${VALUES_FILE}"

echo "Helm deployment completed successfully."
