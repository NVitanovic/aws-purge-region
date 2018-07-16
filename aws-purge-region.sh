#!/bin/bash
TMP_FILE="/tmp/opp.txt"
TMP_FILE2="/tmp/opp2.txt"

if [ "$#" -lt "1" ]; then
    echo "ERROR: Not enough arguments passed, run with --help to get more info!"
    exit 1
fi

# Load the command and optional parameters
COMMAND=$1
PARAMETERS=$2

# Check if aws API is available
aws sts get-caller-identity
if [ "$?" -ne 0 ]; then
    echo "ERROR: Connection to AWS API failed, please check your credentials!"
    exit 1
fi

function single() {
    REGION_NAME=$1
    # If parameter not specified
    if [ -z "$1" ]; then
        return 1
    fi
    # Go trough all instances
    aws ec2 describe-instances --output text --region $REGION_NAME > $TMP_FILE
    echo "INSTANCES" >> $TMP_FILE # Hack so the last instance gets terminated
    if [ "$?" -ne 0 ]; then
        echo "ERROR: Could not retrieve instance list from specified reason!"
        return 2
    fi
    while IFS='' read -r line || [[ -n "$line" ]]; do
        # Lets parse line by line and go trough all instances,
        # terminate them and then remove their security group
        COMMAND=`echo $line | awk '{print $1}'`
        if [ "$COMMAND" = "INSTANCES" ]; then
            # If we had a previous instance then terminate it and wait - 48 terminated state
            if [ ! -z "$INSTANCE_ID" ] && [ ! -z "$INSTANCE_STATE" ] && [ "$INSTANCE_STATE" -ne "48" ]; then 
                echo "INFO: Starting termination of $INSTANCE_ID..."
                aws ec2 terminate-instances --instance-ids $INSTANCE_ID --output text --region $REGION_NAME > /dev/null
                if [ $? -eq 0 ]; then
                    # If termination is successful then wait for it to change state
                    # Try to terminate in order to get the status
                    STATE=`aws ec2 terminate-instances --instance-ids $INSTANCE_ID --output text --region $REGION_NAME | grep CURRENTSTATE | awk '{print $2}'`
                    # While not terminated check the status
                    while [ "$STATE" -ne "48" ]; do
                        STATE=`aws ec2 terminate-instances --instance-ids $INSTANCE_ID --output text --region $REGION_NAME | grep CURRENTSTATE | awk '{print $2}'`
                        echo "INFO: Waiting for instance $INSTANCE_ID to terminate..."
                        sleep 5
                    done
                    echo "INFO: Instance $INSTANCE_ID terminated, deleting security group $INSTANCE_SECURITY_GROUP."
                    aws ec2 delete-security-group --group-id $INSTANCE_SECURITY_GROUP --output text --region $REGION_NAME
                    if [ $? -ne "0" ]; then
                        echo "WARNING: Could not delete security group $INSTANCE_SECURITY_GROUP, skipping..."
                    fi
                else
                    echo "WARNING: Could not terminate instance $INSTANCE_ID skipping..."
                fi
            else
                # New instance is found, so we need to start parsing it
                INSTANCE_ID=`echo $line | awk '{print $8}'`
                continue
            fi
            # We found a new instance, reset variables and fill them gradually
            INSTANCE_ID=""
            INSTANCE_STATE=""
            INSTANCE_SECURITY_GROUP=""
        elif [ "$COMMAND" = "STATE" ]; then
            INSTANCE_STATE=`echo $line | awk '{print $2}'`
        elif [ "$COMMAND" = "SECURITYGROUPS" ]; then
            INSTANCE_SECURITY_GROUP=`echo $line | awk '{print $2}'`
        fi
    done < "$TMP_FILE"
    # Remove now all the keypairs
    aws ec2 describe-key-pairs --output text --region $REGION_NAME > $TMP_FILE2
    while IFS='' read -r line || [[ -n "$line" ]]; do
        KEYPAIR_NAME=`echo $line | awk '{print $3}'`
        echo "INFO: Deleting keypair $KEYPAIR_NAME..."
        aws ec2 delete-key-pair --key-name $KEYPAIR_NAME --output text --region $REGION_NAME > /dev/null
        if [ $? -ne 0 ]; then
            echo "WARNING: Could not delete keypair $KEYPAIR_NAME, skipping..."
        fi
    done < "$TMP_FILE2"
    return 0
}

# Check if single project exists, and delete resources and then project
if [ "$COMMAND" = "--single" ]; then
    echo "INFO: Purge starting!"
    single $PARAMETERS
    echo "INFO: Purge done!"
# Go trough all projects and remove all except admin or services
elif [ "$COMMAND" = "--all" ]; then
    echo "INFO: Not yet implemented!"
else
    echo "ERROR: Invalid command specified, check help for more info!"
fi

rm $TMP_FILE
rm $TMP_FILE2