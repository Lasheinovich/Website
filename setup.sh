#!/bin/bash

set -euxo pipefail  # Stop on errors, log commands, and fail fast on piped commands

echo "🚀 Starting AI Project Setup & Auto-Healing in WSL..."

# Define variables
REQ_FILE="requirements.txt"
VENV_PATH="venv"
MAX_RETRIES=10  # Maximum retries for fixing dependencies
RETRY_COUNT=0
FASTAPI_PORT=8000
PYTHON_VERSION="python3.10"  # Adjust to your required version

# Ensure WSL & System Packages Are Updated
echo "🔄 Updating WSL system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# Ensure Python is installed
if ! command -v "$PYTHON_VERSION" &>/dev/null; then
    echo "❌ Python $PYTHON_VERSION is not installed! Installing now..."
    sudo apt-get install -y "$PYTHON_VERSION" "$PYTHON_VERSION-venv"
fi

# Ensure Virtual Environment Exists
if [ ! -d "$VENV_PATH" ]; then
    echo "🔧 Creating Python virtual environment..."
    "$PYTHON_VERSION" -m venv "$VENV_PATH"
fi

# Activate Virtual Environment
source "$VENV_PATH/bin/activate"

# Ensure pip is up-to-date
echo "📦 Upgrading pip..."
pip install --upgrade pip

# List of known problematic system packages
PROBLEM_SYSTEM_PACKAGES=("command-not-found" "distro-info" "fail2ban" "gyp")

# Check and remove problematic system packages
for pkg in "${PROBLEM_SYSTEM_PACKAGES[@]}"; do
    if dpkg -l | grep -q "$pkg"; then
        echo "⚠️ Removing problematic package: $pkg..."
        sudo apt-get remove --purge -y "$pkg"
    fi
done

# Function to install dependencies with retries
install_dependencies() {
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        echo "📦 Attempting to install dependencies (Attempt: $((RETRY_COUNT+1)))..."
        if pip install --no-cache-dir -r "$REQ_FILE"; then
            echo "✅ Dependencies installed successfully!"
            return 0
        fi

        # Detect missing or problematic packages
        ERROR_LOG=$(pip install --no-cache-dir -r "$REQ_FILE" 2>&1 || true)
        if echo "$ERROR_LOG" | grep -q "ERROR: Could not find a version"; then
            echo "⚠️ Detected problematic dependencies! Removing conflicts..."
            BAD_PACKAGE=$(echo "$ERROR_LOG" | grep "ERROR: Could not find a version" | awk '{print $6}' | tr -d '()' | sort -u)
            for package in $BAD_PACKAGE; do
                echo "⚠️ Removing package: $package..."
                pip uninstall -y "$package" || true
            done
        fi

        RETRY_COUNT=$((RETRY_COUNT + 1))
        sleep 5
    done

    echo "❌ Failed to install dependencies after $MAX_RETRIES attempts."
    exit 1
}

# Install dependencies
install_dependencies

# Ensure FastAPI is running
check_fastapi() {
    if lsof -i :$FASTAPI_PORT | grep LISTEN; then
        echo "✅ FastAPI is running on port $FASTAPI_PORT."
    else
        echo "🚀 Starting FastAPI server..."
        nohup uvicorn main:app --host 0.0.0.0 --port $FASTAPI_PORT --reload > fastapi.log 2>&1 &
        echo "🟢 FastAPI started and logging to fastapi.log"
    fi
}

check_fastapi

# Optional: Docker Setup
setup_docker() {
    if ! command -v docker &>/dev/null; then
        echo "🐳 Docker is not installed. Installing Docker..."
        sudo apt-get install -y docker.io
        sudo systemctl start docker
        sudo systemctl enable docker
    else
        echo "✅ Docker is already installed."
    fi
}

# Ask if Docker is needed
read -p "Do you want to set up Docker support? (y/n): " setup_docker_choice
if [[ "$setup_docker_choice" == "y" ]]; then
    setup_docker
fi

echo "🎉 AI Project is Now Fully Operational! 🚀"
