# Stage 1: Build dependencies in a temporary image
FROM python:3.11-slim AS builder

# Environment optimizations for performance & reliability
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Set working directory inside the container
WORKDIR /app

# Install system dependencies for Python libraries
RUN apt-get update && apt-get install -y \
    gcc \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy only the requirements file to leverage Docker cache efficiently
COPY requirements.txt .

# Validate & Install dependencies (Stops if any package fails)
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir --prefix=/install -r requirements.txt \
    || (echo "🚨 Dependency installation failed. Check requirements.txt!" && exit 1)


# Stage 2: Create final lightweight image
FROM python:3.11-slim

# Create a non-root user for security
RUN adduser --disabled-password --gecos '' fastapi

# Set working directory inside the container
WORKDIR /app

# Copy installed dependencies from builder stage
COPY --from=builder /install /usr/local

# Copy the actual project files
COPY . .

# Set file permissions & ownership to prevent permission errors
RUN chown -R fastapi:fastapi /app

# Switch to non-root user
USER fastapi

# Expose the application port
EXPOSE 8000

# Define FastAPI startup command
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
