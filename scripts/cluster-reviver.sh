#!/usr/bin/env bash
set -euo pipefail

EXPECTED_CONTEXT_PATTERN="${EXPECTED_CONTEXT_PATTERN:-staging}"
ROOT_APP_URL="${ROOT_APP_URL:-https://raw.githubusercontent.com/<LeDangQuocAn>/banking-gitops/main/argocd/staging/root/root-application.yaml}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
ARGOCD_RELEASE_NAME="${ARGOCD_RELEASE_NAME:-argocd}"
ARGO_HELM_REPO_NAME="${ARGO_HELM_REPO_NAME:-argo}"
ARGO_HELM_REPO_URL="${ARGO_HELM_REPO_URL:-https://argoproj.github.io/argo-helm}"

log() {
  printf '[INFO] %s\n' "$*"
}

fail() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

log "Checking prerequisites"
require_cmd kubectl
require_cmd helm

log "Validating kubectl context"
CURRENT_CONTEXT="$(kubectl config current-context 2>/dev/null || true)"
[ -n "$CURRENT_CONTEXT" ] || fail "No kubectl current-context is configured"
case "$CURRENT_CONTEXT" in
  *"$EXPECTED_CONTEXT_PATTERN"*)
    ;;
  *)
    fail "Current context '$CURRENT_CONTEXT' does not match expected pattern '$EXPECTED_CONTEXT_PATTERN'"
    ;;
esac

log "Validating cluster connectivity"
kubectl get namespace >/dev/null 2>&1 || fail "Unable to reach cluster with current kubectl context"

log "Installing/upgrading ArgoCD in namespace '$ARGOCD_NAMESPACE'"
helm repo add "$ARGO_HELM_REPO_NAME" "$ARGO_HELM_REPO_URL" >/dev/null 2>&1 || true
helm repo update >/dev/null
kubectl create namespace "$ARGOCD_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
helm upgrade --install "$ARGOCD_RELEASE_NAME" "$ARGO_HELM_REPO_NAME/argo-cd" \
  --namespace "$ARGOCD_NAMESPACE" \
  --wait \
  --timeout 10m

log "Applying Root Application from public raw URL"
kubectl apply -f "$ROOT_APP_URL"

cat <<EOF

ArgoCD bootstrap completed.

Get initial ArgoCD admin password:
kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

Port-forward ArgoCD UI:
kubectl -n $ARGOCD_NAMESPACE port-forward svc/argocd-server 8080:443

Open UI:
https://localhost:8080
Username: admin

EOF
