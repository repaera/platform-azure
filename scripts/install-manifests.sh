#!/bin/bash
# Install core cluster manifests after k3s bootstrap.
# Usage: ./scripts/install-manifests.sh [OPTIONS]
#
# Options:
#   --skip-redis           Skip self-hosted Redis installation
#   --skip-opensearch      Skip self-hosted OpenSearch installation
#   --db-provider=TYPE     Install self-hosted DB inside k3s (postgres|mysql|none)
#                          Default: none (BYO-DB via managed service)
#   --postgres-password    PostgreSQL admin password (required if db-provider=postgres)
#   --mysql-password       MySQL admin password (required if db-provider=mysql)
#   --help                 Show this help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

INSTALL_REDIS=true
INSTALL_OPENSEARCH=true
DB_PROVIDER="none"
POSTGRES_PASSWORD=""
MYSQL_PASSWORD=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-redis)
      INSTALL_REDIS=false
      shift
      ;;
    --skip-opensearch)
      INSTALL_OPENSEARCH=false
      shift
      ;;
    --db-provider=*)
      DB_PROVIDER="${1#*=}"
      shift
      ;;
    --db-provider)
      DB_PROVIDER="$2"
      shift 2
      ;;
    --postgres-password)
      POSTGRES_PASSWORD="$2"
      shift 2
      ;;
    --mysql-password)
      MYSQL_PASSWORD="$2"
      shift 2
      ;;
    --help)
      head -n 16 "$0" | tail -n 15
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Run with --help for usage."
      exit 1
      ;;
  esac
done

echo "[1/5] Installing Traefik (Helm)..."
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --set service.type=LoadBalancer

echo "[2/5] Installing cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl rollout status deployment/cert-manager -n cert-manager --timeout=120s

if [[ "$INSTALL_REDIS" == true ]]; then
  echo "[3/5] Installing Redis (self-hosted StatefulSet)..."
  kubectl apply -f "${MANIFESTS_DIR}/redis/"
  echo "[info] Redis installed. To use a managed service instead, run with --skip-redis"
else
  echo "[3/5] Skipping Redis (use --skip-redis flag). Install Upstash or Azure Cache separately."
fi

if [[ "$INSTALL_OPENSEARCH" == true ]]; then
  echo "[4/5] Installing OpenSearch (self-hosted StatefulSet)..."
  kubectl apply -f "${MANIFESTS_DIR}/opensearch/"
  echo "[info] OpenSearch installed. To use a managed service instead, run with --skip-opensearch"
else
  echo "[4/5] Skipping OpenSearch (use --skip-opensearch flag). Install Elastic Cloud or Meilisearch separately."
fi

case "$DB_PROVIDER" in
  postgres)
    if [[ -z "$POSTGRES_PASSWORD" ]]; then
      echo "ERROR: --postgres-password required when --db-provider=postgres"
      exit 1
    fi
    echo "[5/5] Installing PostgreSQL (self-hosted via Helm)..."
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    helm upgrade --install postgres bitnami/postgresql \
      --namespace database \
      --create-namespace \
      --set auth.postgresPassword="$POSTGRES_PASSWORD" \
      --set auth.database=app \
      --set primary.persistence.storageClass=longhorn \
      --set primary.persistence.size=20Gi
    echo "[info] Self-hosted PostgreSQL installed at postgres.database.svc.cluster.local"
    echo "[warning] Self-hosted DB is NOT recommended for production data. Use managed service for critical workloads."
    ;;
  mysql)
    if [[ -z "$MYSQL_PASSWORD" ]]; then
      echo "ERROR: --mysql-password required when --db-provider=mysql"
      exit 1
    fi
    echo "[5/5] Installing MySQL (self-hosted via Helm)..."
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    helm upgrade --install mysql bitnami/mysql \
      --namespace database \
      --create-namespace \
      --set auth.rootPassword="$MYSQL_PASSWORD" \
      --set auth.database=app \
      --set primary.persistence.storageClass=longhorn \
      --set primary.persistence.size=20Gi
    echo "[info] Self-hosted MySQL installed at mysql.database.svc.cluster.local"
    echo "[warning] Self-hosted DB is NOT recommended for production data. Use managed service for critical workloads."
    ;;
  none)
    echo "[5/5] Skipping database installation (BYO-DB)."
    echo "[info] Connect your apps to managed PostgreSQL/MySQL via Doppler or Kubernetes Secrets."
    echo "[info] To install a self-hosted DB for budget savings, re-run with --db-provider=postgres or --db-provider=mysql"
    ;;
  *)
    echo "ERROR: Unknown db-provider: $DB_PROVIDER. Use: postgres, mysql, or none"
    exit 1
    ;;
esac

echo "[done] Cluster bootstrap complete."
