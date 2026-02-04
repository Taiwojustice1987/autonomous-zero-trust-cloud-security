#!/bin/bash

echo "Deploying Zero Trust Cloud Infrastructure..."

# Navigate to Terraform folder
cd terraform || exit

# Initialize and apply Terraform
./terraform.exe init
./terraform.exe plan -out=tfplan
./terraform.exe apply -auto-approve

echo "Terraform deployment complete."

# Run compliance checks
cd ../compliance || exit
python nist_checks.py

# Run AI anomaly detection
cd ../ai || exit
python anomaly_detection.py

echo "Zero Trust Cloud Security deployment and checks completed!"