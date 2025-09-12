# Base image Python 3.10 slim
FROM python:3.10-slim

# Cài build tools & thư viện cần thiết cho dlib/opencv
RUN apt-get update && apt-get install -y \
    build-essential cmake \
    libopenblas-dev liblapack-dev \
    libx11-dev libgtk-3-dev \
    libboost-python-dev \
    git wget unzip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Tạo working directory
WORKDIR /app

# Copy requirements và cài dependencies
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copy code vào container
COPY . .

# Cài đặt Flask route để route function dựa trên URL
# Chạy functions-framework với main.py
CMD ["functions-framework", "--target=app", "--port=8080"]
