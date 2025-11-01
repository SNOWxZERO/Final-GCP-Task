FROM python:3.8-slim

# set a working directory
WORKDIR /app

# ensure stdout/stderr are not buffered (helpful for logging)
ENV PYTHONUNBUFFERED=1

# install build dependencies and cleanup
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential gcc \
    && rm -rf /var/lib/apt/lists/*

# copy requirements first to leverage docker layer caching
COPY requirements.txt ./

# install python deps
RUN pip install --no-cache-dir -r requirements.txt

# copy the application
COPY . /app

# sensible defaults for running inside a container
ENV PORT=8888 \
    HOST=0.0.0.0 \
    ENVIRONMENT=DEV \
    REDIS_HOST=redis \
    REDIS_PORT=6379 \
    REDIS_DB=0

EXPOSE ${PORT}

CMD ["python", "hello.py"]
