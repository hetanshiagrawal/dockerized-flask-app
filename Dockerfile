FROM python:3.12-slim

# Don't write .pyc files; flush logs straight to stdout
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install dependencies first so this layer is cached when only app code changes
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Run as a non-root user (bonus)
RUN useradd --create-home appuser && chown -R appuser /app
USER appuser

EXPOSE 5000
CMD ["python", "app.py"]
