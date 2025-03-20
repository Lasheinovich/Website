# Use official Python image as the base
FROM python:3.10-slim AS base

# Set working directory inside the container
WORKDIR /app

# Install necessary system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    libssl-dev \
    libffi-dev \
    python3-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry for dependency management (Optional)
RUN pip install --no-cache-dir poetry

# Copy the application files into the container
COPY . /app

# Use a Python virtual environment to prevent conflicts
RUN python -m venv /venv
ENV PATH="/venv/bin:$PATH"

# Install dependencies inside the virtual environment
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Expose the FastAPI default port
EXPOSE 8000

# Command to run FastAPI using Uvicorn in production mode
CMD ["gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "server:app", "--bind", "0.0.0.0:8000"]

