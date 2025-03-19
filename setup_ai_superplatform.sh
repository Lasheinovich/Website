#!/bin/bash
set -e  # Exit on error

PROJECT_NAME="AI_SuperPlatform"
PROJECT_DIR="$HOME/$PROJECT_NAME"
LOG_FILE="$PROJECT_DIR/setup.log"

echo "🚀 Starting AI SuperPlatform Setup..." | tee -a "$LOG_FILE"

# Step 1: Create Project Directory
echo "📁 Creating project directory: $PROJECT_DIR" | tee -a "$LOG_FILE"
mkdir -p "$PROJECT_DIR" && cd "$PROJECT_DIR"

# Step 2: Initialize Git
echo "🔧 Initializing Git repository..." | tee -a "$LOG_FILE"
git init
git remote add origin "https://github.com/YourUsername/$PROJECT_NAME.git"
git fetch origin main
git reset --hard origin/main
git clean -fd
git pull origin main --rebase

# Step 3: Setup Python Virtual Environment
echo "🐍 Setting up Python Virtual Environment..." | tee -a "$LOG_FILE"
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate

# Step 4: Install Dependencies
echo "📦 Installing dependencies..." | tee -a "$LOG_FILE"
pip install --upgrade pip
pip install fastapi uvicorn sqlalchemy passlib[bcrypt] python-jose[cryptography] pyjwt
pip freeze > requirements.txt
git add requirements.txt
git commit -m "Updated dependencies" || true

# Step 5: Start FastAPI Server
echo "✅ Starting FastAPI Server..." | tee -a "$LOG_FILE"
uvicorn app.main:app --host 0.0.0.0 --port 8000 &

# Step 6: Deploy to Railway & Fly.io
echo "🚀 Deploying to Railway & Fly.io..." | tee -a "$LOG_FILE"
fly auth login || true
fly launch || true
fly deploy || true
railway login || true
railway init || true
railway up || true

# Step 7: Push Changes to GitHub
echo "📤 Pushing latest changes to GitHub..." | tee -a "$LOG_FILE"
git push origin main || echo "⚠️ Git push failed. Check manually."

echo "🎉 AI SuperPlatform setup is complete!" | tee -a "$LOG_FILE"
