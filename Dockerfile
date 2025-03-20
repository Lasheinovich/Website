# ================================
# Stage 1: Dependency Installation
# ================================
FROM python:3.11-slim AS builder

# Environment optimizations
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

WORKDIR /app

# ================================
# Install System Dependencies
# ================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl nano unzip fail2ban \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ================================
# Install Python Dependencies
# ================================
COPY requirements.txt .

# Install dependencies separately to leverage Docker caching
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Check & Auto-Fix Dependency Conflicts
RUN pip check || (echo "🚨 Dependency conflict detected! Auto-fixing..." && \
    pip install --no-cache-dir pipdeptree && \
    pipdeptree --warn silence | grep '->' | cut -d ' ' -f1 | xargs pip install --no-cache-dir)

# Remove unnecessary files to keep the image small
RUN rm -rf /root/.cache/pip

# ================================
# Stage 2: Final Clean Image
# ================================
FROM python:3.11-slim

WORKDIR /app

# Add a non-root user for security
RUN adduser --disabled-password --gecos '' fastapi
RUN chown -R fastapi:fastapi /app
USER fastapi  

# Copy necessary files from the builder stage
COPY --from=builder /usr/bin/fail2ban /usr/bin/fail2ban
COPY --from=builder /usr/bin/curl /usr/bin/curl
COPY --from=builder /usr/bin/nano /usr/bin/nano

# Copy application source code
COPY . .

# Expose API port
EXPOSE 8000

# Run FastAPI with multiple workers for performance
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
