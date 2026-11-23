# ==============================================================================
# Speakaboo Backend - Production Dockerfile
# ==============================================================================

FROM python:3.11-slim as base

# Set environment flags
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8000 \
    DATABASE_PATH=/app/data/speakaboo.db

WORKDIR /app

# Install system dependencies (curl for container healthcheck)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create dedicated non-root application user
RUN groupadd -g 1001 speakaboo && \
    useradd -u 1001 -g speakaboo -s /bin/bash -m appuser

# Install Python production dependencies
COPY backend/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy backend application source code
COPY backend /app/backend

# Create data directory for SQLite persistence and set permissions
RUN mkdir -p /app/data && chown -R appuser:speakaboo /app

# Switch to non-root user
USER appuser

# Expose HTTP port
EXPOSE 8000

# Container healthcheck probe
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/api/health || exit 1

# Production ASGI server entry point
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2", "--proxy-headers", "--forwarded-allow-ips", "*"]
