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
~/bin/aws ec2 authorize-security-group-ingress --region $AWS_REGION --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 \
          --cidr $RUNNER_IP/24

# give ingrees rule time to propagate
sleep 7

# steps to deploy
# docker should already be installed, just need to copy repo code

echo "DEPLOYING REPO"

scp -r $CIRCLE_PROJECT_REPONAME $EC2_USERNAME@$EC2_PUBLIC_IP:~/
ssh -o StrictHostKeyChecking=no $EC2_USERNAME@$EC2_PUBLIC_IP \
    cd $CIRCLE_PROJECT_REPONAME \
    npm run build:prod \
    npm run start:prod \
    echo "DEPLOYED ${CIRCLE_PROJECT_REPONAME} SUCCESFULLY"

# remove ingress rule
~/bin/aws ec2 revoke-security-group-ingress --region $AWS_REGION --group-id $SECURITY_GROUP_ID \
        --protocol tcp --port 22 --cidr $RUNNER_IP
