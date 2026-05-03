#!/bin/bash
# Install core cluster infrastructure — all via Helm.
# Usage: ./scripts/install-manifests.sh [OPTIONS]
#
# Installs by default:
#   - Traefik (ingress controller)
#   - cert-manager v1.14.5 (TLS certificates, pinned)
#   - Longhorn (distributed storage)
#   - Doppler (secrets operator)
#   - Rancher (cluster UI + management)
#   - Redis (single-node, Bitnami)
#   - OpenSearch (single-node, Bitnami)
#   - Optional: PostgreSQL or MySQL (Bitnami)
#
# Options:
#   --skip-redis           Skip self-hosted Redis (use Upstash, etc.)
#   --skip-opensearch      Skip self-hosted OpenSearch (use managed search)
#   --skip-doppler         Skip Doppler secrets operator (use manual K8s Secrets)
#   --db-provider=TYPE     Install self-hosted DB: postgres, mysql, or none (default)
#   --postgres-password    Required when --db-provider=postgres
#   --mysql-password       Required when --db-provider=mysql
#   --rancher-hostname     Custom domain for Rancher (e.g., rancher.yourdomain.com)
#                          If omitted, Rancher uses a placeholder hostname.
#                          Update DNS A-record to point to your LB IP before accessing.
#   --help                 Show this help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../manifests"

INSTALL_REDIS=true
INSTALL_OPENSEARCH=true
INSTALL_DOPPLER=true
DB_PROVIDER="none"
POSTGRES_PASSWORD=""
MYSQL_PASSWORD=""
RANCHER_HOSTNAME=""

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
    --skip-doppler)
      INSTALL_DOPPLER=false
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
    --rancher-hostname=*)
      RANCHER_HOSTNAME="${1#*=}"
      shift
      ;;
    --rancher-hostname)
      RANCHER_HOSTNAME="$2"
      shift 2
      ;;
    --help)
      head -n 31 "$0" | tail -n 30
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Run with --help for usage."
      exit 1
      ;;
  esac
done

# Helper: skip if Helm release already deployed
helm_install_or_upgrade() {
  local release=$1 namespace=$2
  shift 2
  if helm status "$release" -n "$namespace" >/dev/null 2>&1; then
    echo "[skip] $release already installed in $namespace. Using helm upgrade..."
  fi
  helm upgrade --install "$release" "$@"
}

# Add all Helm repos once
echo "[init] Adding Helm repositories..."
helm repo add traefik https://traefik.github.io/charts
helm repo add jetstack https://charts.jetstack.io
helm repo add longhorn https://charts.longhorn.io
helm repo add doppler https://helm.doppler.com
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Step 1: Traefik
echo "[1/8] Installing Traefik (ingress controller)..."
helm_install_or_upgrade traefik traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --set service.type=LoadBalancer

# Step 2: cert-manager (pinned version)
CERT_MANAGER_VERSION="v1.14.5"
echo "[2/8] Installing cert-manager ${CERT_MANAGER_VERSION} (TLS certificates)..."
helm_install_or_upgrade cert-manager cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version "${CERT_MANAGER_VERSION}" \
  --set installCRDs=true

kubectl rollout status deployment/cert-manager -n cert-manager --timeout=180s

# Step 3: Longhorn
echo "[3/8] Installing Longhorn (distributed storage)..."
helm_install_or_upgrade longhorn longhorn-system longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --set defaultSettings.defaultDataPath=/var/lib/longhorn \
  --set persistence.defaultClassReplicaCount=1

kubectl rollout status deployment/longhorn-ui -n longhorn-system --timeout=180s || true

# Step 4: Doppler (default — secrets management)
if [[ "$INSTALL_DOPPLER" == true ]]; then
  echo "[4/8] Installing Doppler Secrets Operator..."
  helm_install_or_upgrade doppler-operator doppler-operator-system doppler/doppler-kubernetes-operator \
    --namespace doppler-operator-system \
    --create-namespace
  echo "[info] Doppler installed. To configure:"
  echo "       1. Get service token from https://dashboard.doppler.com"
  echo "       2. kubectl create secret generic doppler-token-secret \\"
  echo "            --namespace doppler-operator-system \\"
  echo "            --from-literal=serviceToken=dp.st.<your-token>"
  echo "       3. kubectl apply -f ${MANIFESTS_DIR}/doppler/cluster-secret-store.yaml"
else
  echo "[4/8] Skipping Doppler (use --skip-doppler to opt out). Use manual Kubernetes Secrets."
fi

# Step 5: Rancher (always — this is the k3s + Rancher stack)
echo "[5/8] Installing Rancher (cluster UI)..."

# Generate a random bootstrap password (16 chars alphanumeric)
RANCHER_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 16)

# Save credentials to a local file for retrieval
PASSWORD_FILE="${SCRIPT_DIR}/../rancher-bootstrap-password.txt"
echo "$RANCHER_PASSWORD" > "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"

# Use provided hostname or placeholder
if [[ -n "$RANCHER_HOSTNAME" ]]; then
  RANCHER_HOSTNAME_FINAL="$RANCHER_HOSTNAME"
  echo "[info] Using custom hostname: $RANCHER_HOSTNAME_FINAL"
else
  RANCHER_HOSTNAME_FINAL="rancher.local"
  echo "[warning] No --rancher-hostname provided. Using placeholder 'rancher.local'."
  echo "          Update DNS and re-run with --rancher-hostname=yourdomain.com"
fi

# Save hostname for reference
HOSTNAME_FILE="${SCRIPT_DIR}/../rancher-hostname.txt"
echo "$RANCHER_HOSTNAME_FINAL" > "$HOSTNAME_FILE"

helm_install_or_upgrade rancher cattle-system rancher-stable/rancher \
  --namespace cattle-system \
  --create-namespace \
  --set hostname="$RANCHER_HOSTNAME_FINAL" \
  --set bootstrapPassword="$RANCHER_PASSWORD" \
  --set replicas=1

echo "[saved] Rancher bootstrap password written to: rancher-bootstrap-password.txt"
echo "[saved] Rancher hostname written to: rancher-hostname.txt"
echo "[security] Change this password immediately after first login."

# Step 6: Redis (single-node default)
if [[ "$INSTALL_REDIS" == true ]]; then
  echo "[6/8] Installing Redis (single-node, Bitnami)..."
  helm_install_or_upgrade redis redis bitnami/redis \
    --namespace redis \
    --create-namespace \
    --set architecture=standalone \
    --set auth.enabled=false \
    --set master.persistence.storageClass=longhorn \
    --set master.persistence.size=5Gi \
    --set master.resources.requests.memory=512Mi \
    --set master.resources.requests.cpu=250m \
    --set master.resources.limits.memory=1Gi \
    --set master.resources.limits.cpu=500m
  echo "[info] Redis: redis-master.redis.svc.cluster.local:6379"
  echo "[info] To upgrade to master-replica later:"
  echo "       helm upgrade redis bitnami/redis --set architecture=replication"
else
  echo "[6/8] Skipping Redis. Install Upstash or connect to managed Redis."
fi

# Step 7: OpenSearch (Bitnami, single-node)
if [[ "$INSTALL_OPENSEARCH" == true ]]; then
  echo "[7/8] Installing OpenSearch (single-node, Bitnami)..."
  helm_install_or_upgrade opensearch opensearch bitnami/opensearch \
    --namespace opensearch \
    --create-namespace \
    --set mode=standalone \
    --set persistence.storageClass=longhorn \
    --set persistence.size=20Gi \
    --set resources.requests.memory=3Gi \
    --set resources.requests.cpu=500m \
    --set resources.limits.memory=4Gi \
    --set resources.limits.cpu=1000m
  echo "[info] OpenSearch: opensearch.opensearch.svc.cluster.local:9200"
else
  echo "[7/8] Skipping OpenSearch. Use Elastic Cloud or managed alternative."
fi

# Step 8: Database (optional)
case "$DB_PROVIDER" in
  postgres)
    if [[ -z "$POSTGRES_PASSWORD" ]]; then
      echo "ERROR: --postgres-password required when --db-provider=postgres"
      exit 1
    fi
    echo "[8/8] Installing PostgreSQL (self-hosted via Helm)..."
    helm_install_or_upgrade postgres database bitnami/postgresql \
      --namespace database \
      --create-namespace \
      --set auth.postgresPassword="$POSTGRES_PASSWORD" \
      --set auth.database=app \
      --set primary.persistence.storageClass=longhorn \
      --set primary.persistence.size=20Gi
    echo "[info] PostgreSQL: postgres.database.svc.cluster.local:5432"
    echo "[warning] Self-hosted DB is NOT recommended for production data."
    ;;
  mysql)
    if [[ -z "$MYSQL_PASSWORD" ]]; then
      echo "ERROR: --mysql-password required when --db-provider=mysql"
      exit 1
    fi
    echo "[8/8] Installing MySQL (self-hosted via Helm)..."
    helm_install_or_upgrade mysql database bitnami/mysql \
      --namespace database \
      --create-namespace \
      --set auth.rootPassword="$MYSQL_PASSWORD" \
      --set auth.database=app \
      --set primary.persistence.storageClass=longhorn \
      --set primary.persistence.size=20Gi
    echo "[info] MySQL: mysql.database.svc.cluster.local:3306"
    echo "[warning] Self-hosted DB is NOT recommended for production data."
    ;;
  none)
    echo "[8/8] Skipping database installation (BYO-DB)."
    echo "[info] Connect your apps to managed PostgreSQL/MySQL via Doppler or K8s Secrets."
    ;;
  *)
    echo "ERROR: Unknown db-provider: $DB_PROVIDER. Use: postgres, mysql, or none"
    exit 1
    ;;
esac

echo "[done] Cluster bootstrap complete."
echo ""
echo "Next steps:"
echo "  1. Get Traefik LB IP:  kubectl get svc -n traefik"
echo "  2. Configure Doppler:   see manifests/doppler/"
echo "  3. Rancher password:    cat rancher-bootstrap-password.txt"
echo "  4. Rancher hostname:    cat rancher-hostname.txt"
echo "  5. Access Rancher:      https://<your-rancher-hostname> (after DNS is set)"
echo "  6. Deploy your app:     see examples/rails8-solid-cicd/"
echo ""
echo "Important: If you didn't provide --rancher-hostname, set up DNS now:"
echo "  - Create A-record: rancher.yourdomain.com → <your-LB-IP>"
echo "  - Re-run: ../../scripts/install-manifests.sh --rancher-hostname=rancher.yourdomain.com"
