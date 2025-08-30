import json, os, uuid, datetime
import boto3

s3 = boto3.client("s3")
RAW_BUCKET = os.environ["RAW_BUCKET"]
RAW_PREFIX = os.environ.get("RAW_PREFIX", "ingest/")

def lambda_handler(event, context):
    """
    Event example (tests/sample_event.json):
    {
      "user_id": "u-123",
      "action": "page_view",
      "metadata": {"page": "/home"}
    }
    """
    now = datetime.datetime.utcnow().isoformat(timespec="seconds") + "Z"
    record = {
        "user_id": event.get("user_id"),
        "action": event.get("action"),
        "metadata": event.get("metadata", {}),
        "event_time": now
    }

    key = f"{RAW_PREFIX}{now.replace(':','-')}-{uuid.uuid4().hex}.json"
    s3.put_object(
        Bucket=RAW_BUCKET,
        Key=key,
        Body=json.dumps(record).encode("utf-8"),
        ContentType="application/json"
    )

    # Returned payload goes to Step Functions -> Process state
    return {"s3_bucket": RAW_BUCKET, "s3_key": key}
