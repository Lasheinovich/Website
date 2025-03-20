#!/bin/bash

set -e  # Exit on error
set -o pipefail  # Ensure pipes fail properly
set -u  # Treat unset variables as errors

# Configuration
PROJECT_DIR="/mnt/d/Moataz/The AI Project"
FIXED_PROJECT_DIR="/mnt/d/Moataz/The_AI_Project"
IMAGE_NAME="fastapi-app"
CONTAINER_NAME="fastapi-secure"
SECCOMP_PROFILE="seccomp.json"
PORT="${PORT:-8000}"  # Allow setting via environment variable
LOG_FILE="setup.log"

# Logging function
log() {
    echo -e "[ $(date +'%Y-%m-%d %H:%M:%S') ] $1" | tee -a "$LOG_FILE"
}

# Ensure the script is running in WSL
if ! grep -q "WSL" /proc/version; then
    log "❌ This script must be run inside WSL."
    exit 1
fi

# Fix spaces in project directory name
if [[ "$PROJECT_DIR" =~ \  ]]; then
    log "🚨 Space detected in path: $PROJECT_DIR"
    log "🔄 Attempting to rename the directory..."

    if [ ! -d "$FIXED_PROJECT_DIR" ]; then
        mv "$PROJECT_DIR" "$FIXED_PROJECT_DIR" || { log "❌ Failed to rename directory. Run manually in Windows." ; exit 1; }
        log "✅ Renamed to: $FIXED_PROJECT_DIR"
    else
        log "⚠️  The directory $FIXED_PROJECT_DIR already exists. Please move your project manually."
        exit 1
    fi
fi

# Navigate to the project directory
cd "$FIXED_PROJECT_DIR"
log "📂 Current project directory: $(pwd)"

# Ensure required files exist
log "📝 Ensuring required files exist..."

touch Dockerfile requirements.txt .dockerignore update_dockerfile.sh

# Update script paths to handle spaces
log "🔄 Fixing script paths..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
log "📂 Script directory: $SCRIPT_DIR"

# Restart Docker service
log "🔄 Restarting Docker..."
sudo systemctl restart docker || {
    log "❌ Failed to restart Docker. Trying to start manually..."
    sudo dockerd &
    sleep 5
}

# Check Docker status
if ! sudo systemctl status docker | grep -q "active (running)"; then
    log "❌ Docker is not running. Check the service manually."
    exit 1
fi

log "✅ Docker is running."

# Generate a secure seccomp profile if not present
if [ ! -f "$SECCOMP_PROFILE" ]; then
    log "🔒 Generating a default seccomp security profile..."
    docker run --rm --security-opt seccomp=unconfined alpine cat /etc/docker/seccomp.json > "$SECCOMP_PROFILE" || echo "{}" > "$SECCOMP_PROFILE"
fi

# Update Dockerfile
log "📝 Updating Dockerfile..."
cat <<EOF > Dockerfile
# Multi-stage build: Install dependencies in a temporary stage
FROM python:3.11-alpine AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -r requirements.txt

# Final stage: Use a minimal runtime image
FROM python:3.11-alpine
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application files
COPY . .

# Set non-root user for security
RUN adduser -D appuser
USER appuser

# Expose FastAPI port
EXPOSE 8000

# Healthcheck for FastAPI service
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:8000/health || exit 1

# Run FastAPI server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

log "✅ Dockerfile updated successfully!"

# Build the updated Docker image
log "🐳 Building optimized Docker image: $IMAGE_NAME ..."
docker build --no-cache -t $IMAGE_NAME . | tee -a "$LOG_FILE"

# Stop and remove existing container if running
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
    log "🛑 Stopping existing container: $CONTAINER_NAME ..."
    docker stop $CONTAINER_NAME || true
    docker rm $CONTAINER_NAME || true
fi

# Run the updated container securely
log "🚀 Running updated FastAPI container securely..."
docker run -d \
    --name $CONTAINER_NAME \
    --security-opt no-new-privileges:true \
    --security-opt seccomp=$(pwd)/$SECCOMP_PROFILE \
    --read-only \
    --cap-drop=ALL \
    --network none \
    --restart always \
    --memory=512m \
    --cpus="0.5" \
    -p $PORT:8000 \
    $IMAGE_NAME | tee -a "$LOG_FILE"

# Verify the container is running
sleep 5
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}\$"; then
    log "✅ Deployment successful! FastAPI is running on http://localhost:$PORT"
else
    log "❌ Deployment failed. Check logs for details."
    exit 1
fi
