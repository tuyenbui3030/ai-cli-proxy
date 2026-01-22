FROM python:3.12-alpine

# Install docker-cli to execute commands in other containers
RUN apk add --no-cache docker-cli

WORKDIR /app
COPY app.py .

# Unbuffered output for better logging
ENV PYTHONUNBUFFERED=1

CMD ["python", "app.py"]
