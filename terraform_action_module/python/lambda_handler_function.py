# 17th October old creation logic
import os
import json
import boto3

client = boto3.client('autoscaling')
sqs_client = boto3.client('sqs')
ssm_client = boto3.client('ssm')

def lambda_handler(event, context):
    # Enable debugging based on an environment variable (optional)
    debug = os.getenv('DEBUG', 'false').lower() == 'true'
    
    if debug:
        print("Headers:", event.get('headers'))
        print("Body:", event.get('body'))

    # SQS Queue URL
    sqs_queue_url = "https://sqs.eu-west-1.amazonaws.com/543775906229/github-actions-runners-queue.fifo"
    parameter_name = "/ghe-actions-runners/asg/new_desired_capacity"

    try:
        # Check if the body contains the 'action' key with the value 'completed'
        body = json.loads(event.get('body', '{}'))
        action = body.get('action')

        if action == 'queued':
            # Step 1: Retrieve New_Desired_Capacity from Parameter Store
            new_desired_capacity = get_parameter_value(parameter_name)

            if new_desired_capacity is None:
                print("error: 'Failed to retrieve New_Desired_Capacity from Parameter Store.")

            # Increment New_Desired_Capacity
            new_desired_capacity = int(new_desired_capacity) + 1

            # Update the new desired capacity in Parameter Store
            update_parameter_value(parameter_name, str(new_desired_capacity))

            asg_name = "github-actions-runner-asg"  # Get the ASG name from environment variables
            if not asg_name:
                print("Missing AUTO_SCALING_GROUP_NAME environment variable.")

            # Retrieve the current desired capacity, max size, and min size
            asg_response = client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_name])
            current_asg = asg_response['AutoScalingGroups'][0]
            max_size = current_asg['MaxSize']
            min_size = current_asg['MinSize']

            if debug:
                print(f"New desired capacity: {new_desired_capacity}, Max size: {max_size}, Min size: {min_size}")

            # Check if New_Desired_Capacity is within limits
            if new_desired_capacity <= max_size:
                # Update ASG desired capacity
                client.update_auto_scaling_group(AutoScalingGroupName=asg_name, DesiredCapacity=new_desired_capacity)

                print(f"Desired capacity set to {new_desired_capacity}.")

            else:
                # Check if (New_Desired_Capacity - MaxSize) < MinSize
                if new_desired_capacity - max_size <= min_size:
                    # Do nothing, just print the values
                    if debug:
                        print(f"New_Desired_Capacity: {new_desired_capacity}, Max size: {max_size}, Min size: {min_size}")
                    
                        print("Capacity is within limits, no action taken.")
                    
                else:
                    # Send message to SQS
                    message_body = {
                        'message': 'New_Desired_Capacity exceeds max size and difference is larger than the min size.',
                        'asg_name': asg_name,
                        'new_desired_capacity': new_desired_capacity,
                        'max_size': max_size,
                        'min_size': min_size
                    }
                    
                    sqs_client.send_message(
                        QueueUrl=sqs_queue_url,
                        MessageBody=json.dumps(message_body),
                        MessageGroupId="github-actions"
                    )


                    print("Max capacity exceeded, message sent to SQS.")

        else:
            print("error: Action is not completed.")

    except Exception as e:
        print(f"An error occurred: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }


def get_parameter_value(parameter_name):
    """Retrieve the value of a parameter from the Parameter Store."""
    try:
        response = ssm_client.get_parameter(Name=parameter_name)
        return response['Parameter']['Value']
    except Exception as e:
        print(f"Error retrieving parameter {parameter_name}: {str(e)}")
        return None

def update_parameter_value(parameter_name, value):
    """Update the value of a parameter in the Parameter Store."""
    try:
        ssm_client.put_parameter(
            Name=parameter_name,
            Value=value,
            Overwrite=True
        )
    except Exception as e:
        print(f"Error updating parameter {parameter_name}: {str(e)}")
