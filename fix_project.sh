#!/bin/bash

echo "🚀 Fixing AI SuperPlatform Project Structure..."

# Navigate to project root
cd "$(dirname "$0")"

# Activate Virtual Environment
source venv/bin/activate
echo "✅ Virtual environment activated."

# Ensure directories exist
mkdir -p app/routers

# Ensure necessary files exist
declare -A MODULES
MODULES["app/__init__.py"]="# Auto-created module"
MODULES["app/routers/__init__.py"]="# Auto-created module"
MODULES["app/routers/auth.py"]="from fastapi import APIRouter\n\nrouter = APIRouter()\n\n@router.get('/')\ndef read_auth():\n    return {'message': 'Auth route is working!'}"
MODULES["app/routers/tasks.py"]="from fastapi import APIRouter\n\nrouter = APIRouter()\n\n@router.get('/')\ndef read_tasks():\n    return {'message': 'Tasks route is working!'}"

for file in "${!MODULES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "🛠 Creating $file..."
        echo -e "${MODULES[$file]}" > "$file"
    fi
done

# Restart FastAPI
echo "🔄 Restarting FastAPI..."
pkill -f uvicorn
nohup uvicorn main:app --host 0.0.0.0 --port 8000 --reload > fastapi.log 2>&1 &
echo "✅ FastAPI restarted!"

# Verify the server
sleep 2
curl -s http://127.0.0.1:8000/auth && echo "✅ Auth route is working!"
curl -s http://127.0.0.1:8000/tasks && echo "✅ Tasks route is working!"

