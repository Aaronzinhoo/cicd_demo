#!/bin/bash
echo "LOADING CONFIGURATION"

# get public IP of CircleCI runner
RUNNER_IP=$(curl ipinfo.io/ip)

# AWS Configuration
EC2_USERNAME=ubuntu
EC2_PUBLIC_IP=34.209.142.0
AWS_REGION=us-west-2
SECURITY_GROUP_ID=sg-009d6969584c6f353

# add incoming traffic rule (ingress rule)
aws ec2 authorize-security-group-ingress --region $AWS_REGION --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 \
          --cidr $RUNNER_IP/24

# give ingrees rule time to propagate
sleep 7

# steps to deploy
# docker should already be installed, just need to copy repo code
# npm should also be installed into the image as well
echo "DEPLOYING REPO"

# add host id to known hosts to avoid yes/no question from ssh
echo $SERVER_SSH_ID >> ~/.ssh/known_hosts
scp -r project $EC2_USERNAME@$EC2_PUBLIC_IP:~/
ssh -t "${EC2_USERNAME}@${EC2_PUBLIC_IP}" 'bash -ic "
    cd project;
    npm run build:prod; npm run start:prod && echo DEPLOYMENT SUCCESSFUL || (exit_code=$?; (exit $exit_code));
"'
exit_code=$?
# remove ingress rule
aws ec2 revoke-security-group-ingress --region $AWS_REGION --group-id $SECURITY_GROUP_ID \
        --protocol tcp --port 22 --cidr $RUNNER_IP/24

if [ $exit_code -ne 0 ]; then
    echo EXITING UNSUCCESSFULLY
    exit $exit_code
fi
