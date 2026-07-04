# ─── Stage 1: Dependencies ────────────────────────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /app

# Install build tools needed for some packages (e.g. psycopg2, cryptography)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ─── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM python:3.12-slim AS runner

WORKDIR /app

# Only copy installed packages from builder — not gcc, not build headers
COPY --from=builder /install /usr/local

# Copy application source
COPY . .

# Non-root user — security best practice
RUN adduser --disabled-password --gecos "" appuser
USER appuser

EXPOSE 8000

# Production uvicorn: no --reload, explicit worker count, access log on
CMD ["uvicorn", "app.main:app", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--workers", "2", \
     "--access-log"]