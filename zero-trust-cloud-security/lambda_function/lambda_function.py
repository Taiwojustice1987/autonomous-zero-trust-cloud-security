import json
import logging
import os
from datetime import datetime, timezone
from urllib.parse import unquote_plus

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")

def lambda_handler(event, context):
    start_time = datetime.now(timezone.utc)
    logger.info("STEP 1: Zero Trust Lambda invoked")

    # ---- Fail fast on missing env var ----
    alert_bucket = os.environ.get("S3_BUCKET")
    if not alert_bucket:
        logger.error("Missing required environment variable: S3_BUCKET")
        return {
            "statusCode": 500,
            "body": json.dumps({"ok": False, "error": "Missing S3_BUCKET env var"})
        }

    logger.info("STEP 2: Environment variables validated")

    # ---- Parse event safely ----
    record = (event.get("Records") or [{}])[0]
    s3_info = record.get("s3", {})

    observed_bucket = s3_info.get("bucket", {}).get("name")
    raw_key = s3_info.get("object", {}).get("key")
    object_key = unquote_plus(raw_key) if raw_key else None

    event_name = record.get("eventName")
    source_ip = record.get("requestParameters", {}).get("sourceIPAddress")

    logger.info("STEP 3: Event parsed (bucket=%s, key=%s)", observed_bucket, object_key)

    # ---- Build alert payload ----
    alert = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "lambda": getattr(context, "function_name", "unknown"),
        "request_id": getattr(context, "aws_request_id", "unknown"),
        "event_name": event_name,
        "source_ip": source_ip,
        "observed_bucket": observed_bucket,
        "object_key": object_key,
        "control": "ZeroTrust.EventDrivenMonitoring",
        "severity": "INFO",
    }

    # ---- Safe S3 key (no ":" in filenames) ----
    ts_safe = alert["timestamp"].replace(":", "-")
    alert_key = f"alerts/{ts_safe}-{alert['request_id']}.json"

    logger.info("STEP 4: Writing alert to S3 (%s)", alert_key)

    try:
        s3.put_object(
            Bucket=alert_bucket,
            Key=alert_key,
            Body=json.dumps(alert, indent=2).encode("utf-8"),
            ContentType="application/json",
        )
    except Exception as e:
        logger.exception("FAILED: S3 put_object")
        return {
            "statusCode": 500,
            "body": json.dumps({
                "ok": False,
                "error": "Failed to write alert",
                "detail": str(e)
            })
        }

    logger.info("STEP 5: Alert successfully written to S3")

    # ---- Minimal event summary (avoid huge logs) ----
    logger.info(
        "Event summary: %s",
        json.dumps({
            "event_name": event_name,
            "observed_bucket": observed_bucket,
            "object_key": object_key,
            "source_ip": source_ip
        })
    )

    duration_ms = (datetime.now(timezone.utc) - start_time).total_seconds() * 1000
    logger.info("STEP 6: Lambda completed in %.2f ms", duration_ms)

    return {
        "statusCode": 200,
        "body": json.dumps({
            "ok": True,
            "alert_key": alert_key,
            "duration_ms": round(duration_ms, 2)
        })
    }
