# Architecture & Zero Trust Controls

## Event-driven monitoring flow
1. Object upload occurs under `incoming/` in the S3 bucket.
2. S3 invokes the monitoring Lambda function.
3. The Lambda function extracts metadata (bucket, key, event type, source IP when present).
4. A structured alert record is written to `alerts/` as JSON for auditing and downstream analytics.

## Zero Trust controls
- **Least privilege:** the Lambda execution role is scoped to the minimum S3 and CloudWatch permissions.
- **Defense-in-depth (optional but recommended):** an S3 bucket policy constrains access to specific principals.
- **No NAT gateway:** the baseline avoids NAT to reduce unnecessary outbound pathways. Where private subnets are required, traffic flows are controlled.
- **Auditability:** CloudWatch logs + immutable alert objects in S3 provide traceability and support compliance.
