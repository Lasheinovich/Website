#!/bin/bash

set -euxo pipefail  # Stop on errors, log commands, and fail fast on piped commands

echo "🚀 Starting AI Project Self-Healing Fix in WSL..."

# Define variables
REQ_FILE="requirements.txt"
VENV_PATH="venv"
MAX_RETRIES=10  # Maximum retries for fixing dependencies
RETRY_COUNT=0

# Ensure Python is installed
if ! command -v python3 &>/dev/null; then
    echo "❌ Python3 is not installed! Please install it first."
    exit 1
fi

# Ensure Virtual Environment Exists
if [ ! -d "$VENV_PATH" ]; then
    echo "🔧 Creating Python virtual environment..."
    python3 -m venv "$VENV_PATH"
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
if ! pgrep -f "fastapi" > /dev/null; then
    echo "🚀 Starting FastAPI server..."
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload &
else
    echo "✅ FastAPI is already running."
fi

echo "🎉 Fix Complete! AI Project is Now Running."
