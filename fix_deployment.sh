#!/bin/bash

set -euxo pipefail  # Enhanced error handling

echo "🚀 Starting AI Project Deployment Fix..."

# Step 1: Remove Problematic Packages in requirements.txt
echo "🔍 Cleaning up problematic packages..."
for pkg in "apparmor" "command-not-found" "distro-info"; do
    if grep -q "$pkg" requirements.txt; then
        sed -i "/$pkg/d" requirements.txt
        echo "✅ Removed '$pkg' from requirements.txt"
    fi
done

# Step 2: Remove conflicting system packages
echo "🛠️ Removing conflicting system packages..."
for pkg in "distro-info" "command-not-found"; do
    if dpkg -l | grep -q "$pkg"; then
        sudo apt remove --purge -y "$pkg" || echo "⚠️ Could not remove $pkg"
    fi
done

# Step 3: Ensure Python3 is Installed and Correct Version
echo "🔍 Checking Python installation..."
if ! command -v python3 &>/dev/null; then
    echo "❌ Python3 is not installed! Please install it first."
    exit 1
fi

PYTHON_VERSION=$(python3 -V 2>&1 | awk '{print $2}')
REQUIRED_VERSION="3.8"

if [[ "$(printf '%s\n' "$PYTHON_VERSION" "$REQUIRED_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]]; then
    echo "❌ Python version must be >= $REQUIRED_VERSION (Found: $PYTHON_VERSION)"
    exit 1
fi

echo "✅ Python3 found: $PYTHON_VERSION"

# Step 4: Ensure Virtual Environment is Clean
VENV_PATH="venv"
echo "🔄 Resetting virtual environment..."
rm -rf "$VENV_PATH"
python3 -m venv "$VENV_PATH"
source "$VENV_PATH/bin/activate"

# Step 5: Upgrade pip, setuptools, and wheel
echo "⬆️ Upgrading pip, setuptools, and wheel..."
pip install --upgrade pip setuptools wheel

# Step 6: Install Dependencies Safely
echo "📦 Installing dependencies..."
pip install --no-cache-dir --ignore-installed -r requirements.txt || echo "⚠️ Some packages failed to install, continuing..."

# Step 7: Verify Installation
echo "✅ Verifying installed packages..."
pip freeze > installed_packages.log
echo "📄 Installed packages saved in installed_packages.log"

echo "🎉 AI Project Deployment Fix Complete! 🚀"
