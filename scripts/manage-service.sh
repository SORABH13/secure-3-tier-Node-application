#!/usr/bin/env bash
#
# manage-service.sh -- start, stop, or scale the ECS Fargate services at
# runtime without touching Terraform (e.g. cost control outside business
# hours, draining a service for a maintenance window, or manually widening
# capacity ahead of expected load). Terraform still owns the autoscaling
# *policy* (target-tracking CPU, min 2 / max 4 -- see
# infrastructure/modules/ecs); this script is for one-off operational
# overrides, and application autoscaling will resume normal target-tracking
# behavior on top of whatever desired count this sets.
#
# Usage:
#   ./manage-service.sh start <web|api|both> [desired-count]   # default 2
#   ./manage-service.sh stop  <web|api|both>                   # sets desired count to 0
#   ./manage-service.sh scale <web|api|both> <desired-count>
#   ./manage-service.sh status <web|api|both>

set -euo pipefail

CLUSTER="toptal-prod-cluster"

usage() {
  echo "Usage: $0 <start|stop|scale|status> <web|api|both> [desired-count]" >&2
  exit 2
}

ACTION="${1:-}"
TARGET="${2:-}"
[[ -n "$ACTION" && -n "$TARGET" ]] || usage

case "$TARGET" in
  web)  SERVICES=("toptal-prod-web") ;;
  api)  SERVICES=("toptal-prod-api") ;;
  both) SERVICES=("toptal-prod-web" "toptal-prod-api") ;;
  *) usage ;;
esac

set_desired_count() {
  local service="$1" count="$2"
  echo "Setting ${service} desired count to ${count}..."
  aws ecs update-service --cluster "$CLUSTER" --service "$service" --desired-count "$count" >/dev/null
  aws ecs wait services-stable --cluster "$CLUSTER" --services "$service"
  echo "${service} is stable at ${count} task(s)."
}

show_status() {
  local service="$1"
  aws ecs describe-services --cluster "$CLUSTER" --services "$service" \
    --query 'services[0].{service:serviceName,status:status,desired:desiredCount,running:runningCount,pending:pendingCount}' \
    --output table
}

case "$ACTION" in
  start)
    COUNT="${3:-2}"
    for svc in "${SERVICES[@]}"; do set_desired_count "$svc" "$COUNT"; done
    ;;
  stop)
    for svc in "${SERVICES[@]}"; do set_desired_count "$svc" 0; done
    ;;
  scale)
    COUNT="${3:?Usage: $0 scale <web|api|both> <desired-count>}"
    for svc in "${SERVICES[@]}"; do set_desired_count "$svc" "$COUNT"; done
    ;;
  status)
    for svc in "${SERVICES[@]}"; do show_status "$svc"; done
    ;;
  *)
    usage
    ;;
esac
