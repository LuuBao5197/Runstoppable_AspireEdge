# Base image
FROM python:3.10-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential cmake python3-dev \
    libboost-all-dev libopenblas-dev liblapack-dev \
    libx11-dev libgtk-3-dev libsm6 libxext6 libxrender-dev \
    git wget unzip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy all files
COPY . .

# Install Python dependencies
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Run Flask app (bạn dùng functions-framework nếu cần)
CMD ["functions-framework", "--target=app", "--port=8080"]
