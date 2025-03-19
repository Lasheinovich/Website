#!/bin/bash

# Define project paths
PROJECT_DIR="/mnt/d/Moataz/The AI Project/The AI Project"
LOG_FILE="$PROJECT_DIR/auto_update.log"
EMAIL="your_email@example.com"
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/XXX/YYY/ZZZ"  # Replace with actual webhook

cd "$PROJECT_DIR" || { echo "❌ Failed to access project directory!" | tee -a "$LOG_FILE"; exit 1; }

echo "🚀 Starting auto-update at $(date)" | tee -a "$LOG_FILE"

# 1️⃣ 🔄 **Check Internet Before Updating**
ping -c 1 github.com > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ No internet connection! Skipping Git update." | tee -a "$LOG_FILE"
    exit 1
fi

# 2️⃣ 🛠 **Create Backup Before Updating**
echo "📦 Creating a backup before updating..." | tee -a "$LOG_FILE"
tar -czf "backup_$(date +%F_%T | tr ':' '_').tar.gz" app/ || echo "⚠️ Backup failed!" | tee -a "$LOG_FILE"

# 3️⃣ 🧹 **Clean Untracked Files & Reset Git**
echo "🧹 Cleaning untracked files before pulling updates..." | tee -a "$LOG_FILE"
git reset --hard
git clean -fd

# 4️⃣ 🔄 **Git Update (Safe Pull)**
echo "🔄 Pulling latest changes from Git..." | tee -a "$LOG_FILE"
git pull origin main --rebase || { echo "❌ Git pull failed!" | tee -a "$LOG_FILE"; exit 1; }

# 5️⃣ 📁 **Ensure Virtual Environment Exists**
if [ ! -d "venv" ]; then
    echo "⚠️ Virtual environment not found. Creating one..." | tee -a "$LOG_FILE"
    python3 -m venv venv
fi

source venv/bin/activate

# 6️⃣ 📦 **Install Required Dependencies**
echo "🔍 Checking for missing dependencies..." | tee -a "$LOG_FILE"
pip install --upgrade pip
pip install -r requirements.txt || { echo "❌ Dependency installation failed!" | tee -a "$LOG_FILE"; exit 1; }

# 7️⃣ 🧹 **Fix Files & Ensure Project Structure**
mkdir -p app/{routes,models,schemas,services}
touch app/__init__.py app/main.py app/database.py app/config.py
touch app/routes/__init__.py app/routes/users.py app/routes/auth.py app/routes/ai.py
touch app/models/__init__.py app/models/user.py
touch app/schemas/__init__.py app/schemas/user.py
touch app/services/__init__.py app/services/user_service.py
touch .gitignore .env Dockerfile README.md

echo "✅ Project structure verified." | tee -a "$LOG_FILE"

# 8️⃣ 📂 **Git Commit & Push If Needed**
if git diff --quiet; then
    echo "✅ No changes detected, skipping commit." | tee -a "$LOG_FILE"
else
    echo "📂 Committing changes to Git..." | tee -a "$LOG_FILE"
    git add .
    git commit -m "Auto-updated project files and dependencies"
    git push origin main || { echo "❌ Git push failed!" | tee -a "$LOG_FILE"; exit 1; }
fi

# 9️⃣ 🛑 **Stop Running FastAPI Server**
echo "🛑 Stopping old FastAPI process if running..." | tee -a "$LOG_FILE"
pkill -f "uvicorn" || echo "⚠️ No running FastAPI instance found."

# 🔟 🚀 **Restart FastAPI Server**
echo "🚀 Restarting FastAPI server..." | tee -a "$LOG_FILE"
nohup uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 > fastapi.log 2>&1 &

# 🔍 **Health Check**
sleep 5
curl -s http://127.0.0.1:8000/health | grep "healthy"
if [ $? -ne 0 ]; then
    echo "❌ FastAPI is NOT running correctly!" | tee -a "$LOG_FILE"
    echo "FastAPI failed to start!" | mail -s "FastAPI Update Failed" "$EMAIL"
    exit 1
else
    echo "✅ FastAPI is running correctly!" | tee -a "$LOG_FILE"
    curl -X POST -H 'Content-type: application/json' --data '{"text":"✅ FastAPI server updated and restarted successfully!"}' "$SLACK_WEBHOOK_URL"
fi

echo "📅 Update completed at $(date)" | tee -a "$LOG_FILE"
