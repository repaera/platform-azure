#!/bin/bash
# Bootstrap a k3s cluster after Terraform apply.
# Usage: ./scripts/k3sup-init.sh <environment_dir>
# Example: ./scripts/k3sup-init.sh environments/single

set -euo pipefail

ENV_DIR="${1:-}"
if [[ -z "$ENV_DIR" ]]; then
  echo "Usage: $0 <environment_dir>"
  echo "Example: $0 environments/single"
  exit 1
fi

cd "$ENV_DIR"

echo "[1/3] Fetching Terraform outputs..."
INIT_CMD=$(terraform output -raw k3sup_init_command)

echo "[2/3] Running k3sup install on first node..."
echo "$INIT_CMD"
eval "$INIT_CMD"

echo "[3/3] Setting KUBECONFIG..."
export KUBECONFIG=./kubeconfig
echo "KUBECONFIG set to $(pwd)/kubeconfig"
echo "Run: kubectl get nodes"
