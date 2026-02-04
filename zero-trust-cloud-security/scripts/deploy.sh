#!/bin/bash
# =========================
# Zero Trust Cloud Deployment Script
# =========================

echo "Starting Zero Trust deployment..."

# Step 1: Terraform init and apply
echo "Initializing Terraform..."
cd ../terraform
./terraform.exe init

echo "Planning Terraform changes..."
./terraform.exe plan

echo "Applying Terraform changes..."
./terraform.exe apply -auto-approve

# Step 2: Run Compliance Checks
echo "Running NIST compliance checks..."
cd ../compliance
python3 nist_checks.py

# Step 3: Run AI Anomaly Detection
echo "Running AI anomaly detection..."
cd ../ai
python3 anomaly_detection.py

echo "Deployment complete!"
