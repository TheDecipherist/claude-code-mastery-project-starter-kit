<!-- Part of /new-project scaffolding. Read via .claude/commands/new-project.md when the selection requires it; not a standalone command. -->

## Dokploy on Hostinger VPS (if selected)

When Dokploy is selected as the hosting target, scaffold a complete deployment pipeline:

### Deployment Architecture
```
Code → Docker Build → Local Test → Docker Hub → Dokploy (webhook) → Live
```

### Required Environment Variables (.env.example additions)

```bash
# Dokploy Deployment
DOKPLOY_URL=http://your-vps-ip:3000/api
DOKPLOY_API_KEY=your_dokploy_api_key
DOKPLOY_APP_ID=your_application_id
DOKPLOY_REFRESH_TOKEN=your_webhook_refresh_token

# Docker Hub
DOCKER_HUB_USER=your_docker_username
DOCKER_IMAGE_NAME=your_docker_username/your_app_name

# Region (if multi-region)
DEPLOY_REGION=us
```

### Deployment Script: scripts/deploy.sh

Create this deployment script:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Load environment
source .env

IMAGE="$DOCKER_IMAGE_NAME:latest"
TAG="${1:-latest}"

echo "=== Building Docker image ==="
docker build -t "$IMAGE" .

echo "=== Testing locally ==="
docker run -d -p 3000:3000 --name deploy-test "$IMAGE"
sleep 5

if ! curl -sf http://localhost:3000 > /dev/null; then
  echo "ERROR: Local test FAILED. Aborting deployment."
  docker logs deploy-test
  docker stop deploy-test && docker rm deploy-test
  exit 1
fi

echo "Local test PASSED."
docker stop deploy-test && docker rm deploy-test

echo "=== Pushing to Docker Hub ==="
docker push "$IMAGE"

echo "=== Deploying via Dokploy ==="
RESPONSE=$(curl -s -X POST \
  -H "x-api-key: $DOKPLOY_API_KEY" \
  -H "Content-Type: application/json" \
  "$DOKPLOY_URL/application.deploy" \
  -d "{\"applicationId\":\"$DOKPLOY_APP_ID\"}")

echo "Dokploy response: $RESPONSE"
echo "=== Deployment complete ==="
```

### Dokploy API Reference (for CLAUDE.md)

Add these to the project's CLAUDE.md when Dokploy is selected:

```markdown
## Deployment Commands

### Deploy (build, test, push, deploy)
bash scripts/deploy.sh

### Dokploy API (direct)
# List all projects
curl -s -H "x-api-key: $DOKPLOY_API_KEY" "$DOKPLOY_URL/project.all"

# Deploy application
curl -s -X POST -H "x-api-key: $DOKPLOY_API_KEY" -H "Content-Type: application/json" \
  "$DOKPLOY_URL/application.deploy" -d '{"applicationId":"APP_ID"}'

# Redeploy (rebuild)
curl -s -X POST -H "x-api-key: $DOKPLOY_API_KEY" -H "Content-Type: application/json" \
  "$DOKPLOY_URL/application.redeploy" -d '{"applicationId":"APP_ID"}'

# Start / Stop
curl -s -X POST -H "x-api-key: $DOKPLOY_API_KEY" -H "Content-Type: application/json" \
  "$DOKPLOY_URL/application.start" -d '{"applicationId":"APP_ID"}'

# Webhook deploy (no auth needed — use refresh token)
curl -X POST http://your-vps-ip:3000/api/deploy/REFRESH_TOKEN
```

### Multi-Region Support (if selected)

When `multiregion` is selected, scaffold for US + EU:

```bash
# .env.example additions for multi-region
DOKPLOY_URL_US=http://us-vps-ip:3000/api
DOKPLOY_API_KEY_US=your_us_api_key
DOKPLOY_APP_ID_US=your_us_app_id

DOKPLOY_URL_EU=http://eu-vps-ip:3000/api
DOKPLOY_API_KEY_EU=your_eu_api_key
DOKPLOY_APP_ID_EU=your_eu_app_id
```

**CRITICAL multi-region rules (add to CLAUDE.md):**
- US containers NEVER connect to EU databases, and vice versa
- Each container gets region-specific `STRICTDB_URI` (e.g., `STRICTDB_URI_US`, `STRICTDB_URI_EU`)
- `DEPLOY_REGION` env var must match the VPS region
- When pushing images: push `:latest` for US, push `:eu` tag for EU
- ALWAYS deploy to both regions — never leave them out of sync

### scripts/deploy-all.sh (multi-region)

```bash
#!/usr/bin/env bash
set -euo pipefail
source .env

IMAGE="$DOCKER_IMAGE_NAME"

# Build and test locally first
docker build -t "$IMAGE:latest" .
docker run -d -p 3000:3000 --name deploy-test "$IMAGE:latest"
sleep 5
curl -sf http://localhost:3000 > /dev/null || { echo "FAILED"; docker logs deploy-test; docker stop deploy-test; docker rm deploy-test; exit 1; }
docker stop deploy-test && docker rm deploy-test

# Push both tags
docker push "$IMAGE:latest"
docker tag "$IMAGE:latest" "$IMAGE:eu"
docker push "$IMAGE:eu"

# Deploy to both regions
echo "Deploying to US..."
curl -s -X POST -H "x-api-key: $DOKPLOY_API_KEY_US" -H "Content-Type: application/json" \
  "$DOKPLOY_URL_US/application.deploy" -d "{\"applicationId\":\"$DOKPLOY_APP_ID_US\"}"

echo "Deploying to EU..."
curl -s -X POST -H "x-api-key: $DOKPLOY_API_KEY_EU" -H "Content-Type: application/json" \
  "$DOKPLOY_URL_EU/application.deploy" -d "{\"applicationId\":\"$DOKPLOY_APP_ID_EU\"}"

echo "=== Both regions deployed ==="
```

