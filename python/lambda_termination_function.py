import json
import boto3
import os

# Initialize the necessary AWS clients
autoscaling_client = boto3.client('autoscaling')
ec2_client = boto3.client('ec2')
sqs_client = boto3.client('sqs')
ssm_client = boto3.client('ssm')

def lambda_handler(event, context):
    # Enable debugging based on an environment variable
    debug = os.getenv('DEBUG', 'true').lower() == 'true'

    if debug:
        print("Headers:", event.get('headers'))
        print("Body:", event.get('body'))

    # Function to update the new desired capacity in the Parameter Store
    def update_new_desired_capacity():
        try:
            # Step 1: Get the current value of the parameter
            response = ssm_client.get_parameter(
                Name='/ghe-actions-runners/asg/new_desired_capacity',
                WithDecryption=False  # Assuming the value is not encrypted
            )
            current_value = int(response['Parameter']['Value'])

            # Step 2: Decrease the value by 1
            new_value = max(0, current_value - 1)  # Ensure it doesn't go below 0

            # Step 3: Update the parameter store with the new value
            ssm_client.put_parameter(
                Name='/ghe-actions-runners/asg/new_desired_capacity',
                Value=str(new_value),
                Overwrite=True
            )

            if debug:
                print(f"Updated new desired capacity in Parameter Store to {new_value}.")
            return new_value

        except Exception as e:
            print(f"Error updating desired capacity in Parameter Store: {str(e)}")
            raise

    # Check if the body contains the 'action' key with the value 'completed'
    try:
        body = json.loads(event.get('body', '{}'))
        action = body.get('action')
        
        if action == 'completed':
            # Extract runner_name and convert it to private IP
            runner_name = body['workflow_job']['runner_name']
            private_ip = runner_name.replace("ip-", "").replace("-", ".")

            if debug:
                print(f"Converted runner_name '{runner_name}' to private IP: {private_ip}")
            
            try:
                # Find the EC2 instance with the private IP
                ec2_response = ec2_client.describe_instances(
                    Filters=[
                        {'Name': 'private-ip-address', 'Values': [private_ip]}
                    ]
                )
                
                reservations = ec2_response.get('Reservations', [])
                if not reservations:
                    raise Exception(f"No running EC2 instance found with private IP {private_ip}")

                instance_id = reservations[0]['Instances'][0]['InstanceId']

                if debug:
                    print(f"Found instance ID: {instance_id}")

                # Step 1: Check the SQS Queue for messages
                sqs_url = "https://sqs.eu-west-1.amazonaws.com/543775906229/github-actions-runners-queue.fifo"
                sqs_response = sqs_client.receive_message(
                    QueueUrl=sqs_url,
                    MaxNumberOfMessages=1,  # Retrieve a single message
                    WaitTimeSeconds=2
                )

                # If the queue has a message, delete it and terminate the instance only
                if 'Messages' in sqs_response:
                    message = sqs_response['Messages'][0]
                    receipt_handle = message['ReceiptHandle']

                    # Delete the message
                    sqs_client.delete_message(
                        QueueUrl=sqs_url,
                        ReceiptHandle=receipt_handle
                    )

                    if debug:
                        print(f"Deleted message from SQS queue: {message['MessageId']}")

                    # Terminate the instance only
                    ec2_client.terminate_instances(InstanceIds=[instance_id])
                    print(f"Terminated instance {instance_id} due to message in the queue.")

                    # Update the desired capacity in Parameter Store
                    update_new_desired_capacity()

                    # Return here to stop further processing
                    return {
                        'statusCode': 200,
                        'body': json.dumps(f"Terminated instance {instance_id}. Message was present in SQS queue.")
                    }

                # If no message in the queue, continue with desired capacity logic
                asg_name = 'github-actions-runner-asg'  # Replace with your ASG name
                response = autoscaling_client.describe_auto_scaling_groups(
                    AutoScalingGroupNames=[asg_name]
                )
                
                asg = response['AutoScalingGroups'][0]
                current_desired_capacity = asg['DesiredCapacity']
                min_size = asg['MinSize']

                if debug:
                    print(f"Current desired capacity: {current_desired_capacity}, Minimum size: {min_size}")

                # Step 2: Check if desired capacity is greater than the minimum size
                if current_desired_capacity > min_size:
                    # Decrease the desired capacity by 1 and terminate the instance
                    new_desired_capacity = max(min_size, current_desired_capacity - 1)

                    autoscaling_client.set_desired_capacity(
                        AutoScalingGroupName=asg_name,
                        DesiredCapacity=new_desired_capacity,
                        HonorCooldown=False  # Set to True if you want to respect cooldowns
                    )
                    
                    print(f"Updated desired capacity for ASG {asg_name} to {new_desired_capacity}.")

                    # Remove the scale-in protection from the EC2 instance
                    autoscaling_client.set_instance_protection(
                        InstanceIds=[instance_id],
                        AutoScalingGroupName=asg_name,
                        ProtectedFromScaleIn=False
                    )

                    # Update the desired capacity in Parameter Store
                    update_new_desired_capacity()

                else:
                    # Just terminate the instance without changing the desired capacity
                    print(f"Desired capacity is equal to the minimum size ({min_size}). Only terminating the instance.")
                
                    ec2_client.terminate_instances(InstanceIds=[instance_id])
                    print(f"Terminated instance {instance_id}.")

                    # Update the desired capacity in Parameter Store
                    update_new_desired_capacity()

                return {
                    'statusCode': 200,
                    'body': json.dumps(f'Processed instance {instance_id}. Desired capacity: {current_desired_capacity}, Min size: {min_size}.')
                }

            except Exception as e:
                print(f"Error: {str(e)}")
                return {
                    'statusCode': 500,
                    'body': json.dumps(f'Error: {str(e)}')
                }

        return {
            'statusCode': 200,
            'body': json.dumps('No action taken.')
        }

    except json.JSONDecodeError:
        print("Failed to parse JSON body")
        return {
            'statusCode': 400,
            'body': json.dumps('Invalid JSON format.')
        }
