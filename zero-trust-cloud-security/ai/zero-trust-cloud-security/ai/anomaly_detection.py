import boto3
from datetime import datetime, timedelta

# AWS region
REGION = "us-east-1"

# Initialize Boto3 clients
logs_client = boto3.client('logs', region_name=REGION)

# Define VPC Flow Log Group
LOG_GROUP = "/zero-trust/vpc-flow-logs"

# Time range for the query: last 1 hour
end_time = int(datetime.utcnow().timestamp())
start_time = end_time - 3600  # 1 hour ago

def get_flow_logs():
    try:
        streams = logs_client.describe_log_streams(
            logGroupName=LOG_GROUP,
            orderBy='LastEventTime',
            descending=True
        )['logStreams']

        for stream in streams[:5]:  # check last 5 streams
            events = logs_client.get_log_events(
                logGroupName=LOG_GROUP,
                logStreamName=stream['logStreamName'],
                startTime=start_time * 1000,
                endTime=end_time * 1000,
                limit=50
            )['events']

            for event in events:
                message = event['message']
                # Example: Detect public traffic to private subnet
                if "ACCEPT" in message and "10.0.1." in message:
                    print(f"[ALERT] Possible internal anomaly detected: {message}")

    except Exception as e:
        print(f"Error reading flow logs: {e}")

if __name__ == "__main__":
    print("Running AI anomaly detection on VPC flow logs...")
    get_flow_logs()
    print("Detection run complete.")
