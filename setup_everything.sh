#!/bin/bash

echo "🚀 Initializing AI-Powered Comprehensive Project Setup 🚀"

# Install Dependencies
sudo apt update
sudo apt install -y python3 python3-pip python3-venv git docker docker-compose nodejs npm

# Setup directories
echo "📁 Creating project directories..."
mkdir -p ai_superplatform/{backend/{fastapi,django,flask},frontend/{nextjs,svelte},ai_models,blockchain,quantum,iot,ar_vr,cybersecurity,databases/{postgres,mongodb,redis,vector_db},devops/{docker,kubernetes,terraform}}

cd ai_superplatform

# Backend Setup
echo "🐍 Setting up Python environments..."
python3 -m venv backend/venv
source backend/venv/bin/activate
pip install --upgrade pip fastapi uvicorn django flask sqlalchemy pymongo neo4j langchain openai tensorflow torch transformers celery redis pinecone-client weaviate-client

# Django Project
cd backend/django
django-admin startproject superplatform .

# FastAPI Project
cd ../fastapi
touch main.py requirements.txt Dockerfile
echo -e "fastapi\nuvicorn[standard]" >> requirements.txt

# Flask Project
cd ../flask
touch app.py requirements.txt Dockerfile
echo -e "flask" >> requirements.txt

# Frontend Setup
echo "🌐 Setting up frontend Next.js app..."
cd ../../frontend/nextjs
npx create-next-app@latest superplatform_frontend --use-npm --ts --eslint

# Databases Setup (Docker Compose)
echo "🐳 Configuring Docker Compose for databases..."
cd ../../devops/docker
cat > docker-compose.yml <<EOF
version: '3.8'
services:
  postgres:
    image: postgres:latest
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: superplatform
    ports:
      - "5432:5432"
  redis:
    image: redis:latest
    ports:
      - "6379:6379"
  mongodb:
    image: mongo:latest
    ports:
      - "27017:27017"
EOF

docker-compose up -d

# Git Initialization
echo "🎛 Initializing Git repository..."
cd ../../
git init
cat > .gitignore <<EOF
__pycache__/
node_modules/
venv/
.env
EOF

git add .
git commit -m "Initial project structure with all possible integrations"

echo "✅ Project initialized! Start coding your AI-powered super platform!"
