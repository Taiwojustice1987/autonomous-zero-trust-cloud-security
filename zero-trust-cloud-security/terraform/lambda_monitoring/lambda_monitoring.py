import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    logger.info("vpc_flow_monitor invoked")
    logger.info("Event: %s", json.dumps(event))
    return {"statusCode": 200, "body": "monitor ok"}
