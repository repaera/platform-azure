# Rancher + k3s on Azure

Modular Terraform template that provisions a **k3s compute cluster** on Azure. Designed for portability and flexibility: bring your own databases, caches, and search from any provider (Upstash, DigitalOcean, AWS, etc.), or self-host them inside k3s.

**Three deployment paths:**
- **`environments/single/`** — One VM for dev / local testing (~$140/mo)
- **`environments/staging/`** — 1 server + 1 agent with LB for pre-production validation (~$175/mo)
- **`environments/multiple/`** — 3-node HA control plane + scalable workers for production (~$386/mo min)

All infrastructure is driven by variables — module `.tf` files never need editing between deployments.

---

## Philosophy: Compute Only, Bring Your Own Data

This template provisions **VMs, network, and load balancer**. Everything else is your choice:

| Service | Default | Escape Hatches |
|---------|---------|----------------|
| **Ingress** | Traefik (Helm) | N/A |
| **TLS** | cert-manager v1.14.5 (Helm, pinned) | N/A |
| **Storage** | Longhorn (Helm) | N/A |
| **Secrets** | Doppler operator (Helm) | `--skip-doppler` → manual K8s Secrets |
| **Redis** | Single-node via Bitnami Helm | `--skip-redis` → Upstash / Azure Cache |
| **OpenSearch** | Single-node via Bitnami Helm | `--skip-opensearch` → Elastic Cloud / Meilisearch |
| **PostgreSQL** | **BYO-DB** (no default) | Terraform `modules/datastore/postgres/` opt-in / managed provider |
| **MySQL** | **BYO-DB** (no default) | Terraform `modules/datastore/mysql/` opt-in / managed provider |

This matches the minimal infrastructure philosophy: **own the compute layer, outsource the state layer**.

---

## Architecture

### Single-Node Path
```
1 × D4as_v5 VM (4 vCPU, 16 GB)
  ├─ k3s server
  ├─ Traefik (Helm)
  ├─ cert-manager (Helm, pinned)
  ├─ Longhorn (Helm)
  ├─ Doppler (Helm)
  ├─ Rancher (Helm)
  ├─ Redis (Helm, skippable)
  ├─ OpenSearch (Helm, skippable)
  └─ Your apps (Rails/Next.js/Go/Rust)

No Azure Load Balancer (Traefik binds to VM public IP)
```

### Multiple (HA) Path
```
3 × D2as_v5 servers (2 vCPU, 8 GB) — etcd + control plane
  ├─ Traefik (Helm)
  ├─ cert-manager (Helm, pinned)
  ├─ Longhorn (Helm)
  ├─ Doppler (Helm)
  ├─ Rancher (Helm)
  └─ Monitoring

1+ × D4as_v5 agents (4 vCPU, 16 GB) — workers, scalable
  ├─ Redis (Helm, skippable)
  ├─ OpenSearch (Helm, skippable)
  └─ Your apps

Azure Load Balancer (Standard)
  ├─ HTTP probe → 80
  ├─ HTTPS probe → 443
  └─ K8s API probe → 6443
```

---

## Directory Structure

```
.
├── modules/
│   ├── common/                 # Provider, versions, resource group
│   ├── networking/             # VNet, subnet, NSG (standalone rules)
│   ├── compute/                # VMs with for_each, identity, zones
│   ├── loadbalancer/           # LB, probes, rules (HTTPS probe on 443)
│   ├── datastore/              # Database modules (opt-in)
│   │   ├── postgres/           # Azure PostgreSQL Flexible Server
│   │   └── mysql/              # Azure MySQL Flexible Server
├── environments/
│   ├── single/                 # 1-node dev / local testing
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   ├── staging/                # 1 server + 1 agent with LB for pre-production
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   └── multiple/               # 3-node HA production
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
├── scripts/
│   ├── k3sup-init.sh           # Bootstrap first node
│   └── install-manifests.sh    # Install all core infrastructure via Helm
├── manifests/
│   └── doppler/                # Doppler ClusterSecretStore + ExternalSecret examples
├── examples/
│   ├── rails8-solid-cicd/      # Rails 8 + GitHub Actions CI/CD to k3s
│   │   ├── Dockerfile
│   │   ├── manifests/          # Kubernetes YAML (namespace, deployment, service, ingress, job)
│   │   └── .github/
│   │       └── workflows/
│   │           └── deploy.yml  # GitHub Actions: build → push GHCR → deploy to k3s
│   └── rails8-solid-rancher/   # Rails 8 + Rancher UI manual deploy
│       ├── Dockerfile
│       └── config/             # database.yml, production.rb for Solid Stack
├── README.md
└── .gitignore
```

**Reusable components live in `modules/`.** Environment directories only orchestrate modules and set variables.

---

## Prerequisites

| Tool      | Purpose                                      | Install |
|-----------|----------------------------------------------|---------|
| az CLI    | Azure authentication and service principal   | `curl -sL https://aka.ms/InstallAzureCLIDeb \| sudo bash` |
| Terraform | Provision all Azure infrastructure           | HashiCorp apt repo |
| k3sup     | Install k3s on VMs over SSH                  | `curl -sLS https://get.k3sup.dev \| sh && sudo mv k3sup /usr/local/bin/` |
| kubectl   | Talk to the cluster                          | Latest release binary |
| helm      | Install ALL infrastructure (required)        | `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \| bash` |

Terraform install via HashiCorp apt repo:

```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### SSH Key Setup

Generate a dedicated key pair for infrastructure access (**do NOT use your personal key**):

```bash
ssh-keygen -t ed25519 -C "platform-azure-infra" -f ~/.ssh/platform-azure-infra
```

- **Private key** (`~/.ssh/platform-azure-infra`): Used by k3sup to bootstrap nodes via SSH. Keep secret.
- **Public key** (`~/.ssh/platform-azure-infra.pub`): Referenced in `terraform.tfvars` as `ssh_public_key_path`.

**Why not `id_rsa`?** Your personal key likely has access to GitHub, other servers, and your workstation. A dedicated key limits blast radius and is easy to rotate without affecting other systems.

---

## Step 1 — Authenticate with Azure

```bash
az login --use-device-code
az account set --subscription "<your-subscription-id>"
```

Create a service principal for Terraform:

```bash
az ad sp create-for-rbac \
  --name "terraform-sp" \
  --role Contributor \
  --scopes /subscriptions/<your-subscription-id>
```

Export the output values (add to `~/.bashrc` to persist):

```bash
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
export ARM_TENANT_ID="<tenant>"
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"
```

---

## Step 2 — Configure Variables

### Single-Node (Dev / Staging)

```bash
cd environments/single
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
```

Minimum required:
- `project` — short prefix for resource names
- `allowed_ssh_cidr` — your IP with `/32` suffix

### Multiple (HA / Production)

```bash
cd environments/multiple
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
```

Same minimums, plus you may want to adjust `server_count` (must be odd) and `agent_count`.

---

## Step 3 — Provision Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

After apply completes, the outputs print ready-to-run commands for k3sup.

---

## Step 4 — Install k3s

### Single-Node

```bash
# Copy and run the init command from Terraform output
terraform output -raw k3sup_init_command
```

### Multiple

```bash
# 1. Bootstrap first server
terraform output -raw k3sup_init_command

# 2. Join remaining servers
for cmd in $(terraform output -json k3sup_join_commands | jq -r '.[]'); do
  echo "$cmd"
done

# 3. Join agents
for cmd in $(terraform output -json k3sup_agent_commands | jq -r '.[]'); do
  echo "$cmd"
done
```

Verify all nodes are ready:

```bash
export KUBECONFIG=./kubeconfig
kubectl get nodes
```

---

## Step 5 — Install Core Infrastructure (One Script, All Helm)

A single script installs the entire stack. Every component is deployed via Helm — no raw YAML, no `kubectl apply -f`.

```bash
../../scripts/install-manifests.sh
```

This installs, in order:

| # | Component | Chart | Namespace | Notes |
|---|-----------|-------|-----------|-------|
| 1 | **Traefik** | `traefik/traefik` | `traefik` | Ingress controller, LoadBalancer service |
| 2 | **cert-manager** | `jetstack/cert-manager` | `cert-manager` | Pinned to `v1.14.5`, auto-installs CRDs |
| 3 | **Longhorn** | `longhorn/longhorn` | `longhorn-system` | Distributed block storage for all PVCs |
| 4 | **Doppler** | `doppler/doppler-kubernetes-operator` | `doppler-operator-system` | Secrets sync from doppler.com |
| 5 | **Rancher** | `rancher-stable/rancher` | `cattle-system` | Cluster UI, always installed |
| 6 | **Redis** | `bitnami/redis` | `redis` | Single-node, upgradeable to replication |
| 7 | **OpenSearch** | `bitnami/opensearch` | `opensearch` | Single-node, standalone mode |
| 8 | **Database** (optional) | `bitnami/postgresql` or `bitnami/mysql` | `database` | Only if `--db-provider` specified |

### Flags

| Flag | Effect |
|------|--------|
| `--skip-redis` | Skip Redis (use Upstash, Azure Cache, etc.) |
| `--skip-opensearch` | Skip OpenSearch (use managed search) |
| `--skip-doppler` | Skip Doppler operator (use manual K8s Secrets) |
| `--db-provider=postgres` | Self-host PostgreSQL inside k3s (budget option) |
| `--db-provider=mysql` | Self-host MySQL inside k3s (budget option) |
| `--db-provider=none` | Default. Use BYO-DB via Doppler / K8s Secrets |

Examples:

```bash
# Full stack (Traefik, cert-manager, Longhorn, Doppler, Rancher, Redis, OpenSearch)
../../scripts/install-manifests.sh

# Skip Redis and OpenSearch, use managed services
../../scripts/install-manifests.sh --skip-redis --skip-opensearch

# Skip Doppler, use manual Kubernetes Secrets
../../scripts/install-manifests.sh --skip-doppler

# Budget option: self-host PostgreSQL too
../../scripts/install-manifests.sh --db-provider=postgres --postgres-password=strongpass
```

### Why All Helm?

- **Version pinning:** cert-manager is pinned to `v1.14.5` for reproducibility
- **Upgrade safety:** `helm upgrade --install` is idempotent — safe to re-run
- **Rollback:** `helm rollback` if a component upgrade breaks
- **Values-driven:** All configuration in one place (the script), no scattered YAML files

---

## Step 6 — Configure Doppler (Recommended)

Doppler is installed by default. It syncs secrets from [doppler.com](https://doppler.com) into your cluster automatically.

### 1. Get Your Service Token

1. Go to [doppler.com](https://dashboard.doppler.com) → your project → **Service Tokens**
2. Create a token (e.g., `k3s-production`)
3. Copy the token (looks like `dp.st.xxx...`)

### 2. Create the Kubernetes Secret

```bash
kubectl create secret generic doppler-token-secret \
  --namespace doppler-operator-system \
  --from-literal=serviceToken=dp.st.YOUR_TOKEN_HERE
```

### 3. Apply the ClusterSecretStore

```bash
kubectl apply -f ../../manifests/doppler/cluster-secret-store.yaml
```

### 4. Use ExternalSecret in Your Apps

Instead of manually creating secrets, your app manifests use an `ExternalSecret`:

```yaml
# In your app's manifests/ directory
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: rails-app-secrets
  namespace: rails-app
spec:
  secretStoreRef:
    kind: ClusterSecretStore
    name: doppler-secret-store
  target:
    name: rails-app-secrets
    creationPolicy: Owner
  dataFrom:
    - extract:
        key: production  # Your Doppler config name
```

See `manifests/doppler/external-secret-example.yaml` for a complete example.

### Skipping Doppler

If you prefer manual secrets, run the install script with `--skip-doppler` and use standard Kubernetes `Secret` resources instead.

---

## Step 7 — Wire Your Database

### Option A: Managed Service (Recommended)

Provision PostgreSQL/MySQL at any provider (Upstash, DigitalOcean, AWS RDS, Azure, etc.).

Inject the connection string via:

- **Doppler** (recommended — auto-syncs to your cluster)
- **Kubernetes Secret** (manual — see `examples/rails8-solid-cicd/manifests/secret.yaml`)
- **Rancher UI** → Project Secrets (click-to-create)

### Option B: Terraform Opt-In

Add to your environment's `main.tf`:

```hcl
module "postgres_shared" {
  source = "../../modules/datastore/postgres"
  # ... see modules/datastore/postgres/variables.tf for all options
}
```

### Option C: Self-Hosted (Budget)

Use the install script's `--db-provider` flag. This deploys a database via Helm inside k3s.

> **Warning:** Self-hosted databases are NOT recommended for production data. Longhorn provides persistence but is not a substitute for managed backups, PITR, and failover.

---

## Step 8 — Access Rancher

Rancher is installed automatically in Step 5. After the Traefik LoadBalancer gets an IP:

```bash
# Get the LB IP
LB_IP=$(terraform output -raw load_balancer_ip)
# Or for single-node: LB_IP=$(terraform output -raw vm_public_ip)

# Update Rancher hostname (patch the existing ingress)
helm upgrade rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=${LB_IP}.nip.io

# Or patch the existing ingress directly:
# kubectl patch ingress rancher -n cattle-system \
#   --type merge \
#   -p '{"spec":{"rules":[{"host":"'${LB_IP}'.nip.io"}]}}'
```

Access: `https://${LB_IP}.nip.io`

Default credentials: `admin` / `admin`

> **Security:** Change the bootstrap password immediately after first login. Go to **☰ → Users & Authentication** → edit `admin` user.

---

## Step 9 — Deploy Your Rails 8 App (EXAMPLE)

This example demonstrates deploying a **Rails 8** application using the Solid Stack — no Redis or Elasticsearch required. All caching, queueing, and search run through PostgreSQL.

### Prerequisites for Your App

| Service | Rails 8 Default | External Required? |
|---------|-----------------|-------------------|
| Database | PostgreSQL / MySQL | ✅ Yes — BYO-DB |
| Cache | Solid Cache (DB table) | ❌ No |
| Queue | Solid Queue (DB table) | ❌ No |
| Search | pg_search gem with pgvector | ⚠️ Only if using full-text/vector search |
| Assets | Propshaft / Tailwind | Built at Docker image build time |

### Two Deployment Paths

Choose the path that fits your workflow:

- **Path A: GitHub Actions** — `git push main` → auto builds image → deploys to k3s
- **Path B: Rancher UI** — Build image locally → paste into Rancher dashboard → click Deploy

### Solid Queue: Two Deployment Options

Both examples support **two ways to run background jobs** — choose based on your needs:

**Option 1: Puma Plugin (Single Container) — Beginner-friendly**
- Web server + background jobs run in one process
- Set `SOLID_QUEUE_IN_PUMA=true` in environment variables
- Add `plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]` to `config/puma.rb`
- Good for: Getting started, low job volume, simplicity
- Scale by increasing `replicas` in the web Deployment

**Option 2: Separate Worker Deployment (Production Scale)**
- Web server and workers run in separate pods
- Do NOT set `SOLID_QUEUE_IN_PUMA` (or set to `false`)
- Deploy `manifests/worker-deployment.yaml` (CICD path) or create a second Rancher workload
- Workers run: `bin/rails solid_queue:start`
- Good for: High job volume, independent scaling, resource isolation
- Scale web and worker pods independently (e.g., 3 web pods + 2 worker pods)

**Switching between options:** Just change the environment variable and apply/restart. No code changes needed.

---

## Path A: GitHub Actions CI/CD (Automated)

**Best for:** Teams, automated deployments, version control of infrastructure.

**How it works:**
1. Push code to `main` branch
2. GitHub Actions builds Docker image → pushes to GHCR
3. GitHub Actions applies Kubernetes manifests to your k3s cluster
4. Database migrations run automatically

### Setup (One-Time)

**1. Copy the example into your Rails repo:**

```bash
cp -r examples/rails8-solid-cicd/Dockerfile examples/rails8-solid-cicd/.dockerignore your-rails-app/
cp -r examples/rails8-solid-cicd/manifests your-rails-app/
cp -r examples/rails8-solid-cicd/.github your-rails-app/
```

**2. Update manifest placeholders:**

```bash
cd your-rails-app
# Replace with your actual GitHub username
sed -i 's/YOUR_GITHUB_USERNAME/your-actual-username/g' manifests/*.yaml
```

**3. Get your KUBECONFIG (newbie-friendly):**

After `k3sup install` on your first node, a `kubeconfig` file was created in your current directory. You need to give GitHub Actions access to your cluster:

```bash
# On your management machine, after running k3sup:
cat kubeconfig | base64 -w 0
# This outputs a long string. Copy it.
```

Then in GitHub:
1. Go to your Rails repo → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `KUBECONFIG`
4. Value: Paste the long base64 string from above
5. Click "Add secret"

**4. Configure secrets (choose one path):**

**Path A — Doppler (Recommended, default in install script)**

No GitHub Secrets needed for database credentials. Add them to your [Doppler project](https://dashboard.doppler.com) instead:

1. Go to Doppler Dashboard → your project → `production` config
2. Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `DATABASE_URL` | `postgresql://user:pass@host:5432/dbname?sslmode=require` |
| `RAILS_MASTER_KEY` | Output of `cat config/master.key` in your Rails app |
| `RAILS_ENV` | `production` |
| `RAILS_SERVE_STATIC_FILES` | `true` |
| `SOLID_QUEUE_IN_PUMA` | `true` (single container) or omit (separate workers) |

3. The workflow uses an `ExternalSecret` (see `manifests/doppler/external-secret-example.yaml`) that auto-syncs these to your cluster.

**Path B — Manual Kubernetes Secrets (if you used `--skip-doppler`)**

Add these as GitHub repository secrets (same method as `KUBECONFIG` above):

| Secret Name | What It Is | Where to Get It |
|-------------|-----------|-----------------|
| `DATABASE_URL` | PostgreSQL connection string | Your managed DB provider |
| `RAILS_MASTER_KEY` | Encryption key for credentials | `cat config/master.key` in your Rails app |

The workflow applies `manifests/secret.yaml` directly.

**5. Configure your Rails app:**

Copy the example configs:
```bash
cp examples/rails8-solid-cicd/config/database.yml config/database.yml
cp examples/rails8-solid-cicd/config/environments/production.rb config/environments/production.rb
```

Install Solid Stack in your Rails app:
```bash
# Add to Gemfile if not present:
# gem "solid_cache"
# gem "solid_queue"
# gem "pg_search"  # only if you need full-text search

bundle install
bin/rails solid_cache:install
bin/rails solid_queue:install
# bin/rails db:migrate  # run locally or let the deploy handle it
```

Add to `config/puma.rb`:
```ruby
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]
```

**6. Push and watch it deploy:**

```bash
git add .
git commit -m "Add k3s deployment"
git push origin main
```

Go to GitHub → Actions tab → watch the workflow run.

### What the Deploy Does

1. **Build** — Multi-stage Docker build with asset compilation
2. **Push** — Image pushed to GitHub Container Registry (free for public repos)
3. **Migrate** — Kubernetes Job runs `rails db:migrate` before app starts
4. **Deploy** — Rolling update: new pods start, old pods stop (zero downtime)
5. **Verify** — Health checks at `/up` ensure pods are ready before receiving traffic

### Ongoing Deployments

After the initial setup, **every `git push origin main` automatically deploys** your changes:

```bash
# Bug fix
git add .
git commit -m "fix: handle edge case"
git push origin main
# → GitHub Actions rebuilds, migrates, and deploys automatically

# Feature update
git commit -m "feat: add search filtering"
git push origin main
# → Same automatic pipeline

# Configuration change
git commit -m "chore: update log level"
git push origin main
# → Rebuilds and redeploys
```

**Zero downtime:** Kubernetes RollingUpdate stops if new pods fail health checks. Old pods keep running until new ones are healthy.

### Rollback

If a deployment breaks your app, you have three ways to recover:

**1. Automatic (Built-in)**
Kubernetes RollingUpdate stops if new pods fail health checks (`/up` endpoint). Old pods remain running. Your app stays available without intervention.

**2. Manual CLI**
```bash
# Check deployment history
kubectl rollout history deployment/rails-app -n rails-app

# Rollback to previous revision
kubectl rollout undo deployment/rails-app -n rails-app
```

**3. GitHub Actions (Explicit rollback to any version)**
1. Go to GitHub → Actions → "Deploy Rails 8 App to k3s"
2. Click **Run workflow**
3. Enter a specific image tag (e.g., `abc1234` from a previous commit SHA)
4. Click **Run**
5. The workflow skips the build and migrations, and deploys the specified image directly

> **Why skip migrations on rollback?** If newer migrations have already run, rolling back to an older image could cause schema mismatch. Manual intervention is safer.

### Enable Separate Workers (Production Scale)

By default, the workflow deploys web pods only. To add separate worker pods:

1. In `manifests/secret.yaml`, **remove or comment out** `SOLID_QUEUE_IN_PUMA: "true"`
2. Uncomment the worker deployment in `.github/workflows/deploy.yml`:
   ```yaml
   - name: Deploy workers (optional)
     run: |
       kubectl apply -f manifests/worker-deployment.yaml
       kubectl rollout status deployment/rails-worker -n rails-app --timeout=300s
   ```
3. Push to `main` — the workflow now deploys both web and worker pods

Scale workers independently:
```bash
kubectl scale deployment rails-worker --replicas=3 -n rails-app
```

---

## Path B: Rancher UI (Manual Click-to-Deploy)

**Best for:** Testing, solo developers, learning k3s without YAML complexity.

**How it works:**
1. Build Docker image locally
2. Push to a container registry (GHCR, DockerHub)
3. Open Rancher dashboard
4. Paste image URL, set environment variables
5. Click "Create" — Rancher handles the rest

### Setup (One-Time)

Rancher is already installed in Step 5. No additional setup needed.

**1. Copy the example Dockerfile:**

```bash
cp examples/rails8-solid-rancher/Dockerfile your-rails-app/
cp examples/rails8-solid-rancher/.dockerignore your-rails-app/
cp examples/rails8-solid-rancher/config/* your-rails-app/config/
```

**2. Configure your Rails app:**

Same as Path A: install `solid_cache`, `solid_queue`, add Puma plugin, configure database.yml.

### Deploy via Rancher UI

**1. Build and push your image:**

```bash
cd your-rails-app

# Build
docker build -t ghcr.io/YOUR_USERNAME/rails-app:v1 .

# Log in to GitHub Container Registry
docker login ghcr.io -u YOUR_USERNAME -p YOUR_GITHUB_TOKEN

# Push
docker push ghcr.io/YOUR_USERNAME/rails-app:v1
```

**2. Open Rancher and create your app:**

1. Open `https://<your-lb-ip>.nip.io` in your browser
2. Log in with the bootstrap password
3. Click **☰ (hamburger menu) → Workloads → Deployments**
4. Click **Create**

**3. Fill in the deployment form:**

| Field | Value |
|-------|-------|
| Name | `rails-app` |
| Namespace | `default` (or create `rails-app`) |
| Container Image | `ghcr.io/YOUR_USERNAME/rails-app:v1` |
| Ports | Add `3000/TCP` |

**4. Add environment variables:**

Click **Environment Variables** → **Add Variable** for each:

| Variable Name | Value |
|-------------|-------|
| `DATABASE_URL` | `postgresql://user:pass@host:5432/db?sslmode=require` |
| `RAILS_MASTER_KEY` | Your master key from `config/master.key` |
| `RAILS_ENV` | `production` |
| `SOLID_QUEUE_IN_PUMA` | `true` (Option 1: single container) or omit (Option 2: separate workers) |
| `RAILS_SERVE_STATIC_FILES` | `true` |

> **Solid Queue Option:**
> - **Option 1 (single container):** Set `SOLID_QUEUE_IN_PUMA=true`. Web server and jobs run together.
> - **Option 2 (separate workers):** Omit `SOLID_QUEUE_IN_PUMA` or set to `false`. Then create a second workload (see below).

**5. Add a health check:**

Click **Health Check** → **HTTP Request Check**:
- Request Path: `/up`
- Port: `3000`
- Initial Delay: `30`
- Check Interval: `10`

**6. Click Create**

Rancher creates the Deployment, Service, and automatically exposes it.

**7. Run database migrations:**

Before your app can serve traffic, you need to run migrations:

1. In Rancher, go to **Workloads → Jobs → Create**
2. Name: `rails-db-migrate`
3. Container Image: same as your app (`ghcr.io/YOUR_USERNAME/rails-app:v1`)
4. Command: Override with `bundle`, `exec`, `rails`, `db:migrate`
5. Add the same environment variables as your app
6. Click **Create**
7. Wait for Job status = `Complete`

**8. Set up Ingress (custom domain):**

If you want a custom domain instead of the raw IP:

1. In Rancher, go to **Service Discovery → Ingresses → Create**
2. Name: `rails-app`
3. Rules:
   - Host: `your-domain.com` (point DNS A-record to your LB IP)
   - Path: `/`
   - Target Service: `rails-app`
   - Port: `3000`
4. Click **Create**

**9. Add separate workers (Optional — for high job volume):**

If you chose **Option 2** (separate workers) for Solid Queue:

1. In Rancher, go to **Workloads → Deployments → Create**
2. Name: `rails-worker`
3. Container Image: same as your app
4. Command: Override with `bin`, `rails`, `solid_queue:start`
5. Environment Variables: Same as your app, but ensure `SOLID_QUEUE_IN_PUMA` is **not set** or set to `false`
6. Replicas: `1` (or more for high volume)
7. Click **Create**

Now web and worker pods scale independently. Increase `rails-app` replicas for more web traffic, increase `rails-worker` replicas for more background job throughput.

**10. Every code update:**

```bash
docker build -t ghcr.io/YOUR_USERNAME/rails-app:v2 .
docker push ghcr.io/YOUR_USERNAME/rails-app:v2
```

Then in Rancher: **Workloads → Deployments → rails-app → Edit** → update image tag → **Save**. Rancher rolls out the new version. If using separate workers, do the same for `rails-worker`.

**Rollback in Rancher:**
If a new version breaks your app, roll back immediately:
1. Go to **Workloads → Deployments → rails-app**
2. Click **Edit**
3. Change the Container Image back to the previous tag (e.g., `v1` instead of `v2`)
4. Click **Save**
5. Rancher rolls back to the previous version automatically

> **Note:** Rancher UI rollback does not run database migrations. If you rolled forward with a migration, rolling back may cause schema mismatch. Test rollback procedures in staging before production.

---

### Rails 8 Configuration Checklist (Both Paths)

**`config/database.yml` (production):**
```yaml
production:
  adapter: postgresql
  url: <%= ENV["DATABASE_URL"] %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS", 5).to_i %>
  sslmode: require
```

**`config/environments/production.rb` (Solid Stack):**
```ruby
config.cache_store = :solid_cache_store
# Solid Queue: Add to config/puma.rb for Option 1 (single container)
# Remove or skip this if using Option 2 (separate workers)
# config/puma.rb: plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]
```

**`config/puma.rb` (Solid Queue plugin):**
```ruby
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]
```

**Install Solid Stack:**
```bash
bin/rails solid_cache:install
bin/rails solid_queue:install
# For search: add gem 'pg_search', run migrations
bin/rails db:migrate
```

**See `examples/rails8-solid-cicd/Dockerfile` or `examples/rails8-solid-rancher/Dockerfile` for the multi-stage optimized build.**

---

## Cost Reference (East US, pay-as-you-go)

### Single-Node Path (Pure Compute)

| Resource | Spec | Monthly |
|----------|------|---------|
| 1 × VM | D4as_v5 (4 vCPU, 16 GB) | ~$126 |
| 1 × Premium SSD 64GB | P10 | ~$10 |
| 1 × Public IP | Standard | ~$3.60 |
| **Total** | | **~$140/mo** |

### Multiple Path (Pure Compute, Minimum)

| Resource | Spec | Monthly |
|----------|------|---------|
| 3 × Server VMs | D2as_v5 (2 vCPU, 8 GB) | ~$188 |
| 1 × Agent VM | D4as_v5 (4 vCPU, 16 GB) | ~$126 |
| 4 × Premium SSD 64GB | P10 | ~$40 |
| 1 × Load Balancer | Standard | ~$18 |
| 4 × Public IPs | Standard | ~$14 |
| **Total** | | **~$386/mo** |

### Staging Path (Pure Compute)

| Resource | Spec | Monthly |
|----------|------|---------|
| 1 × Server VM | D2as_v5 (2 vCPU, 8 GB) | ~$63 |
| 1 × Agent VM | D2as_v5 (2 vCPU, 8 GB) | ~$63 |
| 2 × Premium SSD 64GB | P10 | ~$20 |
| 1 × Load Balancer | Standard | ~$18 |
| 3 × Public IPs | Standard | ~$11 |
| **Total** | | **~$175/mo** |

**Optional managed alternatives** (if you used `--skip-redis`, `--skip-opensearch`, or `--db-provider=none`):
- Upstash Redis: free tier → ~$20/mo
- DigitalOcean PostgreSQL: ~$15/mo
- Elastic Cloud: ~$200+/mo (or skip/searchless)

---

## Cost Control Runbook

If infrastructure costs approach your budget threshold:

| Scenario | Action | Resulting Cost |
|----------|--------|----------------|
| Comfortable budget, scaling up | Add agents via `terraform apply` | Scales linearly |
| Budget tightening | Reduce `agent_count = 1`, use smaller SKUs | ~$320/mo |
| Pre-production testing | Use `environments/staging/` (1 server + 1 agent) | ~$175/mo |
| Bootstrapping / pre-revenue | Switch to `environments/single/` | ~$140/mo |
| Emergency pause | `terraform destroy` + preserve data via DB backups | $0 (re-create later) |

---

## Scaling the Cluster

### Add Agent Nodes (Zero Downtime)

Edit `terraform.tfvars` in `environments/multiple/`:

```hcl
agent_count = 2  # was 1
```

```bash
terraform apply
# Run new k3sup agent join command from output
```

### Add Managed PostgreSQL via Terraform

Edit `environments/multiple/main.tf`:

```hcl
module "postgres_shared" {
  source       = "../../modules/datastore/postgres"
  resource_group = module.common.resource_group
  project      = var.project
  tags         = module.common.tags
  server_name  = "pgsql-${var.project}-shared"
  admin_password = "strongpassword"
  databases    = ["app1", "app2"]
}
```

Add variables and re-apply.

---

## Teardown

```bash
# Destroy the chosen environment
cd environments/single   # or environments/multiple
terraform destroy
```

This removes all Azure resources. The `terraform.tfvars` file is local only and is not affected.

---

## What's Fixed From the Original Template

| Issue | Fix |
|-------|-----|
| HTTPS LB rule used HTTP probe | Now uses separate HTTPS probe on port 443 |
| K8s API / Rancher open to `*` | Restricted to `management_cidr` (defaults to SSH source) |
| No remote state backend | Backend block ready for Azure Storage (edit `backend` block) |
| No `required_version` pin | Pinned to `~> 1.9` in `modules/common/versions.tf` |
| VMs had no Azure identity | `identity { type = "SystemAssigned" }` on all VMs |
| VMs used `count` (identity churn) | `for_each` with stable names (e.g., `server-0`, `agent-1`) |
| NSG inline rules | Standalone `azurerm_network_security_rule` resources |
| No `node_count` validation | Validates odd numbers ≥ 1 for etcd quorum |
| No Availability Zones | Servers distributed across zones 1/2/3 |
| `.gitignore` only in README | Actual `.gitignore` file created |
| Hardcoded managed DB | Now BYO-DB with opt-in Terraform modules |

---

## As a Module

You can also consume individual modules directly:

```hcl
module "networking" {
  source = "git::https://github.com/repaera/platform-azure.git//modules/networking"
  resource_group   = azurerm_resource_group.rg
  project          = "client-x"
  allowed_ssh_cidr = "x.x.x.x/32"
}
```

---

## Security Best Practices

### 1. Dedicated SSH Keys
- Generate infrastructure-specific keys: `ssh-keygen -t ed25519 -f ~/.ssh/platform-azure-infra`
- Never use your personal `id_rsa` for infrastructure access
- Never commit private keys to git (see `.gitignore`)

### 2. Remote State Backend
- Default is local state (`backend "local" {}`)
- **For teams or production**: Configure Azure Storage backend to prevent state loss and enable locking:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstate<unique>"
    container_name       = "tfstate"
    key                  = "single.terraform.tfstate"
  }
}
```

### 3. Secrets Management
- `terraform.tfvars` contains secrets and is **gitignored by default**
- Never commit `.tfstate` files — they contain plaintext passwords
- Use Doppler, Azure Key Vault, or Kubernetes External Secrets for app-level secrets

### 4. Network Security
- SSH is locked to `allowed_ssh_cidr` (your IP by default)
- K8s API (6443) and Rancher (8443) default to the same CIDR as SSH
- For team access, set `management_cidr` to a shared office IP or VPN range

### 5. VM Identity
- All VMs have `SystemAssigned` managed identity enabled
- Use Azure RBAC to grant least-privilege access (e.g., ACR pull, Key Vault read)
- Never store Azure credentials on VMs

---

## License

This project is licensed under the [Apache License 2.0](LICENSE).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on bug reports, feature requests, and pull requests.

Questions? Contact [tech@repaera.com](mailto:tech@repaera.com).
