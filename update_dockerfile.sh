#!/bin/bash

set -e  # Exit on error
set -o pipefail  # Ensure pipes fail properly
set -u  # Treat unset variables as errors

# Configuration
IMAGE_NAME="fastapi-app"
CONTAINER_NAME="fastapi-secure"
SECCOMP_PROFILE="seccomp.json"
PORT="${PORT:-8000}"  # Allow setting via environment variable
LOG_FILE="deploy.log"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_DIR="${SCRIPT_DIR// /\\ }"  # Escape spaces in path

# Logging function
log() {
    echo -e "[ $(date +'%Y-%m-%d %H:%M:%S') ] $1" | tee -a "$LOG_FILE"
}

# Ensure there are no spaces in the path
if [[ "$SCRIPT_DIR" =~ \  ]]; then
    log "❌ Space detected in path: $SCRIPT_DIR"
    log "🚨 Rename the directory to remove spaces and try again."
    exit 1
fi

# Backup Dockerfile
log "📂 Backing up Dockerfile..."
cp Dockerfile Dockerfile.bak

# Optimize .dockerignore
log "⚡ Ensuring .dockerignore is optimized..."
cat <<EOF > .dockerignore
venv/
__pycache__/
*.pyc
*.pyo
*.log
*.db
node_modules/
.git/
.idea/
.vscode/
EOF

# Build the Docker image
log "🐳 Building optimized Docker image..."
docker build --no-cache -t $IMAGE_NAME .

# Clean up unused Docker layers
log "🧹 Cleaning up Docker build cache..."
docker builder prune -af
docker image prune -af
docker system prune -af

# Stop & remove existing container
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
    log "🛑 Stopping existing container..."
    docker stop $CONTAINER_NAME || true
    docker rm $CONTAINER_NAME || true
fi

# Run updated container securely
log "🚀 Deploying FastAPI container..."
docker run -d \
    --name $CONTAINER_NAME \
    --security-opt no-new-privileges:true \
    --security-opt seccomp=$(pwd)/$SECCOMP_PROFILE \
    --read-only \
    --cap-drop=ALL \
    --network none \
    --restart unless-stopped \
    --memory=512m \
    --cpus="0.5" \
    -p $PORT:8000 \
    $IMAGE_NAME

# Verify if FastAPI is running
sleep 5
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}\$"; then
    log "✅ FastAPI is running at: http://localhost:$PORT"
else
    log "❌ Deployment failed. Check logs for details."
    exit 1
fi

