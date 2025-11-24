FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN python db_init.py || true

COPY . .

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    FLASK_ENV=production

# Argument that selects which app to run (good or bad)
ARG APP_FOLDER=good
ENV APP_FOLDER=${APP_FOLDER}

# Expose ports dynamically
EXPOSE 5000 5001

CMD ["sh", "-c", "python3 ${APP_FOLDER}/vulpy.py"]
