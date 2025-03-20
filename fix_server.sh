#!/bin/bash

echo "🔧 Ensuring virtual environment is activated..."
source venv/bin/activate

echo "📌 Checking if port 8000 is already in use..."
PORT=8000
PID=$(lsof -t -i:$PORT)
if [ ! -z "$PID" ]; then
    echo "⚠️ Port $PORT is in use. Killing process..."
    kill -9 $PID
fi

echo "📦 Reinstalling Uvicorn in virtual environment..."
pip install --no-cache-dir uvicorn

echo "🚀 Starting FastAPI server..."
uvicorn server:app --host 0.0.0.0 --port 8000 --reload
