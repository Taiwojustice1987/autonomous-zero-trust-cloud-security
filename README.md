# Autonomous Zero Trust Cloud Security Framework

This repository contains an autonomous cloud-security framework that applies Zero Trust engineering principles through Infrastructure-as-Code (Terraform), event-driven monitoring, and defense-in-depth controls. The implementation demonstrates how to detect and record cloud storage events in a secure, auditable manner suitable for regulated and critical cloud environments.

## What it does
- Deploys a private AWS network baseline (VPC + private subnet) designed to minimize exposure.
- Uses an event-driven trigger (S3 ObjectCreated) to invoke a Lambda function for monitoring.
- Produces structured alert records (JSON) written to S3 for auditability and downstream analytics.
- Implements least-privilege access controls and optional defense-in-depth bucket enforcement.

## Key design goals
- **Zero Trust posture:** assume breach, minimize implicit trust, and enforce least privilege.
- **No NAT gateway:** reduce unnecessary egress pathways; access AWS services using VPC endpoints where appropriate.
- **Auditability:** generate deterministic, machine-readable alerts to support compliance and forensic review.
- **Reproducibility:** deploy the environment through Terraform for consistent, testable infrastructure.

## Repository structure
- `zero-trust-cloud-security/terraform/` — Infrastructure-as-Code (VPC, IAM, S3, Lambda, triggers, endpoints)
- `zero-trust-cloud-security/lambda_function/` — Event-driven monitoring Lambda (`lambda_function.py`)
- `zero-trust-cloud-security/ai/` — Anomaly-detection pipeline components (extensible)
- `zero-trust-cloud-security/compliance/` — Compliance-check components (extensible)

## High-level validation
An upload to `s3://<bucket>/incoming/` triggers the Lambda function, which writes an alert JSON record to `s3://<bucket>/alerts/` containing:
- event type (e.g., ObjectCreated:Put)
- object key (path)
- source IP (when available)
- timestamp and request ID

