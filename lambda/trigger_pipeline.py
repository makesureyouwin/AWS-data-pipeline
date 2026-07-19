import json
import boto3

stepfunctions = boto3.client('stepfunctions')

STATE_MACHINE_ARN = "arn:aws:states:ap-south-1:886492071822:stateMachine:pipeline-orchestrator"  # we'll fill this in via Terraform output

def lambda_handler(event, context):
    # This function runs automatically whenever a new file lands in S3
    
    # Extract the bucket and file name from the S3 event that triggered this
    record = event['Records'][0]
    bucket = record['s3']['bucket']['name']
    key = record['s3']['object']['key']
    
    print(f"New file detected: {key} in bucket {bucket}")
    
    # Start the Step Functions state machine, passing the file info along
    response = stepfunctions.start_execution(
        stateMachineArn=STATE_MACHINE_ARN,
        input=json.dumps({
            "bucket": bucket,
            "key": key
        })
    )
    
    print(f"Started execution: {response['executionArn']}")
    return {
        'statusCode': 200,
        'body': json.dumps(f"Pipeline started for {key}")
    }