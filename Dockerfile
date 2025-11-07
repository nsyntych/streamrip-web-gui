FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    git \
    gcc \
    python3-dev \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN groupadd -g 1000 appuser && \
    useradd -r -u 1000 -g appuser appuser

# Set working directory
WORKDIR /app

# Create virtualenv and install dependencies inside it
RUN python3 -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir flask flask-cors gunicorn gevent && \
    pip install --no-cache-dir git+https://github.com/omnunum/streamrip.git@main

# Copy application files
COPY app.py /app/
COPY templates /app/templates/
COPY static /app/static/

# Create necessary directories with proper ownership
RUN mkdir -p /logs /data/music/.config && \
    chown -R 1000:1000 /logs /data/music

RUN chown -R 1000:1000 /app/venv/lib/python3.11/site-packages/browserforge

# Switch to non-root user
USER 1000:1000

# Expose port
EXPOSE 5000

# Run app using virtualenv environment
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--worker-class", "gevent", "--workers", "2", "--timeout", "60", "app:app"]
