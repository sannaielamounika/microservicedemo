#!/bin/bash
set -eo pipefail

KNOWN_SERVICES=(
  "auth-service" "user-service" "customer-service" "contact-service"
  "lead-service" "opportunity-service" "quotation-service" "invoice-service"
  "task-service" "file-service" "notification-service" "report-service"
  "gateway-service" "audit-service" "admin-service" "employee-service"
  "hr-service" "manager-service" "holiday-service" "dashboard-service"
)

CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || git diff --name-only origin/master...HEAD 2>/dev/null || true)
SERVICES_TO_BUILD=()

for file in $CHANGED_FILES; do
  for svc in "${KNOWN_SERVICES[@]}"; do
    if [[ "$file" == *"$svc"* ]]; then
      if [[ ! " ${SERVICES_TO_BUILD[*]} " =~ " ${svc} " ]]; then
        SERVICES_TO_BUILD+=("$svc")
      fi
    fi
  done
done

if [ ${#SERVICES_TO_BUILD[@]} -eq 0 ]; then
  echo "auth-service,gateway-service,user-service,admin-service,employee-service,customer-service,hr-service,task-service"
else
  IFS=','
  echo "${SERVICES_TO_BUILD[*]}"
fi
