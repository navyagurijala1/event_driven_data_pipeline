import json, os, boto3, datetime

s3 = boto3.client("s3")
RAW_BUCKET = os.environ["RAW_BUCKET"]

def lambda_handler(event, context):
    """
    Input: {"s3_bucket":"...","s3_key":"..."}
    Output: {"items":[{...}]}  # ready for DynamoDB
    """
    bucket = event["s3_bucket"]
    key    = event["s3_key"]

    obj = s3.get_object(Bucket=bucket, Key=key)
    record = json.loads(obj["Body"].read().decode("utf-8"))

    # Minimal enrichment / transformation
    processed_at = datetime.datetime.utcnow().isoformat(timespec="seconds") + "Z"
    record["processed_at"] = processed_at
    record["is_click"] = (record.get("action") == "click")

    # Writer expects items array
    return { "items": [record] }
