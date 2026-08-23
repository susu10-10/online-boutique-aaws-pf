import json
import boto3
import os

# Initialize the SNS client
sns = boto3.client('sns')
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

def lambda_handler(event, context):
    # Iterate through the SQS message batch
    for record in event['Records']:
        # Extract the raw JSON string from the SQS body
        raw_body = record['body']
        
        try:
            payload = json.loads(raw_body)
            order_id = payload.get('order_id', 'UNKNOWN-ID')
            user_email = payload.get('email', 'UNKNOWN-EMAIL')
            
            # The Payload Architecture
            message = f"Order {order_id} has been successfully processed for {user_email}.\n\nFreedom is coming."
            
            # Push to the SNS Broadcaster
            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject=f"Boutique Order Confirmation: {order_id}",
                Message=message
            )
            print(f"Successfully processed order {order_id}")
            
        except Exception as e:
            print(f"Failed to process record. Error: {str(e)}")
            raise e # Trigger a failure to keep the message in SQS (Dead Letter Queue routing)
            
    return {
        "statusCode": 200,
        "body": json.dumps("Processing complete.")
    }