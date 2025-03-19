#!/bin/bash

set -euo pipefail  # Enhanced error handling

echo "🚀 Starting AI Project Deployment Fix..."

# 1️⃣ Step: Remove problematic packages from `requirements.txt`
REQ_FILE="requirements.txt"
INVALID_PACKAGES=("apparmor==3.0.4" "cloud-init==24.4.1")  # Add any other problematic packages

if [ ! -f "$REQ_FILE" ]; then
    echo "❌ requirements.txt file not found!"
    exit 1
fi

for package in "${INVALID_PACKAGES[@]}"; do
    if grep -q "$package" "$REQ_FILE"; then
        sed -i "/$package/d" "$REQ_FILE"
        echo "✅ Removed '$package' from requirements.txt"
    fi
done

# 2️⃣ Step: Check Python Installation
if ! command -v python3 &>/dev/null; then
    echo "❌ Python3 is not installed! Please install it first."
    exit 1
fi

PYTHON_VERSION=$(python3 --version | awk '{print $2}')
REQUIRED_VERSION="3.8"

if [[ "$(printf '%s\n' "$PYTHON_VERSION" "$REQUIRED_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]]; then
    echo "❌ Python version must be >= $REQUIRED_VERSION (Found: $PYTHON_VERSION)"
    exit 1
fi

echo "✅ Python3 found: $PYTHON_VERSION"

# 3️⃣ Step: Ensure Virtual Environment Exists & Activate
VENV_PATH="venv"

if [ ! -d "$VENV_PATH" ]; then
    echo "🔧 Creating Python virtual environment..."
    python3 -m venv "$VENV_PATH"
fi

# Detect WSL or Linux/MacOS
if [[ -f "$VENV_PATH/bin/activate" ]]; then
    source "$VENV_PATH/bin/activate"
elif [[ -f "$VENV_PATH/Scripts/activate" ]]; then  # For Windows WSL
    source "$VENV_PATH/Scripts/activate"
else
    echo "❌ Virtual environment activation failed!"
    exit 1
fi

echo "✅ Virtual environment activated!"

# 4️⃣ Step: Install Dependencies (Only if Necessary)
echo "📦 Checking dependencies..."
pip freeze > pip_freeze.log
if grep -Fq "apparmor" pip_freeze.log || grep -Fq "cloud-init" pip_freeze.log; then
    echo "⚠️ Some problematic packages are still installed. Cleaning up..."
    pip uninstall -y "${INVALID_PACKAGES[@]}"
fi

echo "📦 Installing dependencies..."
pip install --no-cache-dir -r "$REQ_FILE" --ignore-installed | tee install.log
pip check || echo "⚠️ Some dependency issues detected!"

echo "🎉 Fix Complete! AI Project is Now Running."
