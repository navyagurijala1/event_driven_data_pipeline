import os,boto3

dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ["TABLE_NAME"]
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    """
    Input: {"items": [ {user_id, event_time, ...}, ... ]}
    """
    items = event.get("items", [])
    written = 0
    with table.batch_writer() as batch:
        for item in items:
            # Ensure keys exist
            if "user_id" in item and "event_time" in item:
                batch.put_item(Item=item)
                written += 1
    return {"written": written}
