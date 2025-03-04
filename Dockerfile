# Define a base stage that uses the official python runtime base image
FROM python:3.11-slim AS base

# Add curl for healthcheck

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Set the application directory

WORKDIR /usr/local/app

# Install our requirements.txt

COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Define a stage specifically for development, where it'll watch for
# filesystem changes
# which monitors file changes and is useful for auto-reloading the Flask app

FROM base AS dev
RUN pip install watchdog
ENV FLASK_ENV=development
CMD ["python", "app.py"]

# Define the final stage that will bundle the application for production

FROM base AS final

# Copy our code from the current folder to the working directory inside the container

COPY . .

# Make port 80 available for links and/or publish

EXPOSE 80

# Define our command to be run when launching the container
# -b 0.0.0.0:80 binds the app to port 80.
# --workers 4 runs 4 worker processes to handle multiple requests
# --keep-alive 0 disables keep-alive connections to optimize for short-lived requests
# --log-file - and --access-logfile - send logs to stdout

CMD ["gunicorn", "app:app", "-b", "0.0.0.0:80", "--log-file", "-", "--access-logfile", "-", "--workers", "4", "--keep-alive", "0"]
