#!/bin/bash

mkdir -p ~/.aws
rm -f ~/.aws/config
cat >> ~/.aws/config <<EOF
[default]
output = json
region = us-east-1
EOF

# install AWS command line tools
sudo pip install awscli &>> aws-setup.log

echo " "
echo " "
echo "#######################################################################"
echo "   This script will connect this UCDP image to Amazon Web Services!"
echo " "
echo "    **** You will need to run this command each time you ****"
echo "    **** restart this image and want to deploy to AWS.   ****"
echo " "
echo " ++ You must provide your own AWS Access Key Id and Secret Access Key"
echo " "
echo " ++ Please enter an AWS Region that is nearest to your physical location"
echo " "
echo "           The AWS Regions are:"
echo " "
echo "           'us-east-1' ------------- US East (Northern Virginia)"
echo "           'us-west-1' ------------- US West (Northern California)"
echo "           'us-west-2' ------------- US West (Oregon)"
echo "           'eu-west-1' ------------- EU (Ireland)"
echo "           'eu-central-1' ---------- EU (Frankfurt)"
echo "           'ap-southeast-1' -------- Asia Pacific (Singapore)"
echo "           'ap-northeast-1' -------- Asia Pacific (Tokyo)"
echo "           'sa-east-1' ------------- South America (Sao Paulo)"
echo "           'ap-southeast-2' -------- Asia Pacific (Sydney)"
echo "           'us-gov-west-1' --------- AWS GovCloud (US)"
echo " "
echo " ++ Please leave the 'output' property set to 'json'"
echo " "
echo " ++ This script will instantiate a t2.micro instance on your AWS account"
echo "     This instance is necessary in order for the UrbanCode Deploy agents"
echo "     to be able to communicate back into this image from outside your"
echo "     current network."
echo " "
echo "    If you shutdown the instance on AWS the communication link will be"
echo "     broken and unrepairable.  You would have to run this script again"
echo "     to bring up another instance on AWS to manage the communication link"
echo " "
echo "    This script will generate a new script 'aws-shutdown.sh' that you"
echo "     can use to shutdown the instance on AWS so that you will no longer"
echo "     be charged for it's use."
echo "#######################################################################"
echo " "
echo " "

aws configure

AWS_ID=`cat ~/.aws/credentials | grep aws_access_key_id | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $3}'`
AWS_KEY=`cat ~/.aws/credentials | grep aws_secret_access_key | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $3}'`
AWS_REGION=`cat ~/.aws/config | grep region | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $3}'`

case "$AWS_REGION" in
  us-east-1)
    UBUNTU_TRUSTY_AMI="ami-6889d200"
    ;;

  us-west-1)
    UBUNTU_TRUSTY_AMI="ami-c37d9987"
    ;;

  us-west-2)
    UBUNTU_TRUSTY_AMI="ami-35143705"
    ;;

  eu-west-1)
    UBUNTU_TRUSTY_AMI="ami-edfd6e9a"
    ;;

  ap-southeast-1)
    UBUNTU_TRUSTY_AMI="ami-62546230"
    ;;

  ap-northeast-1)
    UBUNTU_TRUSTY_AMI="ami-8f876e8f"
    ;;

  sa-east-1)
    UBUNTU_TRUSTY_AMI="ami-a757eeba"
    ;;

  ap-southeast-2)
    UBUNTU_TRUSTY_AMI="ami-c94e3ff3"
    ;;

  eu-central-1)
    UBUNTU_TRUSTY_AMI="ami-e6a694fb"
    ;;

  us-gov-west-1)
    UBUNTU_TRUSTY_AMI="ami-1643ff7e"
    ;;

  *)
    ;;
esac

if [[ $UBUNTU_TRUSTY_AMI == "" ]]; then
  echo " "
  echo "======================= ERROR ============================"
  echo "We were unable to locate a known Ubuntu 14.04 Trusty image"
  echo "in your chosen AWS Region ($AWS_REGION). Please run the"
  echo "script again and choose a different AWS Region."
  echo "=========================================================="
  echo " "
fi

# delete existing 'ucdp-demo-key' key-pair
aws ec2 delete-key-pair --key-name ucdp-demo-key
rm -f .ssh/ucdp-demo-key.pem

# create key-pair to use for ssh into instances in pubic/private subnets
aws ec2 create-key-pair --key-name ucdp-demo-key --query 'KeyMaterial' --output text > ucdp-demo-key.pem
chmod 400 ucdp-demo-key.pem
mv ucdp-demo-key.pem .ssh/

# find the "default" VPC for the account
VPC_ID=`aws ec2 describe-vpcs | grep VpcId | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $2}'`

# find a valid subnet attached to the VPC
SUBNET_ID=`aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" | grep SubnetId | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $2}'`

# create the UCD AGENT RELAY host security group
UCD_AGENT_RELAY_SG_ID=`aws ec2 describe-security-groups --filters "Name=group-name,Values=ucd-agent-relay-sg" | grep GroupId | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $2}'`
if [[ "$UCD_AGENT_RELAY_SG_ID" == "" ]]; then
  UCD_AGENT_RELAY_SG_ID=`aws ec2 create-security-group --group-name 'ucd-agent-relay-sg' --description 'UCD Agent Relay security group for the ucd agent relay host.' --vpc-id $VPC_ID | grep GroupId | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $2}'`
  # enable inbound protocols for the UCD_AGENT_RELAY security group
  #aws ec2 authorize-security-group-ingress --group-id $UCD_AGENT_RELAY_SG_ID --protocol -1 --source-group $UCD_AGENT_RELAY_SG_ID
  aws ec2 authorize-security-group-ingress --group-id $UCD_AGENT_RELAY_SG_ID --protocol 'tcp' --port 22 --cidr '0.0.0.0/0'
  aws ec2 authorize-security-group-ingress --group-id $UCD_AGENT_RELAY_SG_ID --protocol 'tcp' --port 20080 --cidr '0.0.0.0/0'
  aws ec2 authorize-security-group-ingress --group-id $UCD_AGENT_RELAY_SG_ID --protocol 'tcp' --port 20081 --cidr '0.0.0.0/0'
  aws ec2 authorize-security-group-ingress --group-id $UCD_AGENT_RELAY_SG_ID --protocol 'tcp' --port 7916 --cidr '0.0.0.0/0'
fi

# create the WAS LIBERTY host security group
WAS_LIBERTY_SG_ID=`aws ec2 describe-security-groups --filters "Name=group-name,Values=was-liberty-sg" | grep GroupId | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $2}'`
if [[ "$WAS_LIBERTY_SG_ID" == "" ]]; then
  WAS_LIBERTY_SG_ID=`aws ec2 create-security-group --group-name 'was-liberty-sg' --description 'WebSphere Liberty security group for your liberty hosted application servers.' --vpc-id $VPC_ID | grep GroupId | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $2}'`
  # enable inbound protocols for the WAS LIBERTY security group
  aws ec2 authorize-security-group-ingress --group-id $WAS_LIBERTY_SG_ID --protocol 'tcp' --port 22 --cidr '0.0.0.0/0'
  aws ec2 authorize-security-group-ingress --group-id $WAS_LIBERTY_SG_ID --protocol 'tcp' --port 9080 --cidr '0.0.0.0/0'
  aws ec2 authorize-security-group-ingress --group-id $WAS_LIBERTY_SG_ID --protocol 'tcp' --port 9081 --cidr '0.0.0.0/0'
  aws ec2 authorize-security-group-ingress --group-id $WAS_LIBERTY_SG_ID --protocol 'tcp' --port 9443 --cidr '0.0.0.0/0'
  aws ec2 authorize-security-group-ingress --group-id $WAS_LIBERTY_SG_ID --protocol 'tcp' --port 3306 --cidr '0.0.0.0/0'
  aws ec2 authorize-security-group-ingress --group-id $WAS_LIBERTY_SG_ID --protocol 'tcp' --port 3389 --cidr '0.0.0.0/0'
fi

# create the MYSQL host security group
MYSQL_SG_ID=`aws ec2 describe-security-groups --filters "Name=group-name,Values=mysql-sg" | grep GroupId | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $2}'`
if [[ "$MYSQL_SG_ID" == "" ]]; then
  MYSQL_SG_ID=`aws ec2 create-security-group --group-name 'mysql-sg' --description 'MySQL security group for your mysql servers.' --vpc-id $VPC_ID | grep GroupId | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $2}'`
  # enable inbound protocols for the UCD_AGENT_RELAY security group
  aws ec2 authorize-security-group-ingress --group-id $MYSQL_SG_ID --protocol 'tcp' --port 22 --cidr '0.0.0.0/0'
  aws ec2 authorize-security-group-ingress --group-id $MYSQL_SG_ID --protocol 'tcp' --port 3306 --cidr '0.0.0.0/0'
  aws ec2 authorize-security-group-ingress --group-id $MYSQL_SG_ID --protocol 'tcp' --port 3389 --cidr '0.0.0.0/0'
fi

# create a new Agent Relay host in the vpc
UCD_AGENT_RELAY_INSTANCE_ID=`aws ec2 run-instances --image-id $UBUNTU_TRUSTY_AMI --count 1 --instance-type t2.micro --key-name ucdp-demo-key --security-group-ids $UCD_AGENT_RELAY_SG_ID --subnet-id $SUBNET_ID --monitoring 'Enabled=true' | grep InstanceId | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $2}'`

# sleep 240s to give time for instance to boot
echo "waiting for Agent Relay instance to boot on AWS in VPC $VPC_ID..."
echo "(this will take a few minutes please be patient)"
i=0
while [ $i -lt 240 ]
do
  sleep 10
  AWS_STATUS=`aws ec2 describe-instance-status --instance-ids $UCD_AGENT_RELAY_INSTANCE_ID --query 'InstanceStatuses[0].[InstanceStatus]' | grep Status | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $2}'`
  if [[ "$AWS_STATUS" == "ok" ]]; then
    i=300
    aws ec2 create-tags --resources $UCD_AGENT_RELAY_INSTANCE_ID --tags Key=Name,Value=ucdp-agent-relay
  fi
  i=$[$i+10]
  printf "."
done
echo "done"

# look up the public dns name of the Agent Relay host
UCD_AGENT_RELAY_PUBLIC_HOST=`aws ec2 describe-instances --filters "Name=instance-id,Values=$UCD_AGENT_RELAY_INSTANCE_ID" | grep PublicIpAddress | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $2}'`
UCD_AGENT_RELAY_PRIVATE_HOST=`aws ec2 describe-instances --filters "Name=instance-id,Values=$UCD_AGENT_RELAY_INSTANCE_ID" | grep PrivateIpAddress | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $2}'`

# create ssh tunnel remote tunnel (forward Agent Relay ports 20080,7916 to this vm on ports 8081,7918)
./tunnel.sh .ssh/ucdp-demo-key.pem $UCD_AGENT_RELAY_PUBLIC_HOST $UCD_AGENT_RELAY_PRIVATE_HOST &>> aws-setup.log


# create Amazon EC2 Cloud Provider in UCDP
EC2_CLOUD_PROVIDER_ID=`curl -s -u ucdpadmin:ucdpadmin \
http://192.168.27.100:9080/landscaper/security/cloudprovider/ | python -c \
"import json; import sys;
data=json.load(sys.stdin);
for item in data:
  if item['name'] == 'AWS':
    print item['id']"`

if [[ "$EC2_CLOUD_PROVIDER_ID" == "" ]]; then

  EC2_CLOUD_PROVIDER_ID=`curl -s -u ucdpadmin:ucdpadmin \
       -H 'Content-Type: application/json' \
       -X POST \
       -d "
    {
      \"name\": \"AWS\",
      \"type\": \"AMAZON\",
      \"costCenterId\": \"\",
      \"properties\": [
        {
          \"name\": \"url\",
          \"value\": \"http://192.168.27.100:8888/identity/v3\",
          \"secure\": false
        },{
          \"name\": \"timeoutMins\",
          \"value\": \"60\",
          \"secure\": false
        },{
          \"name\": \"useDefaultOrchestration\",
          \"value\": \"false\",
          \"secure\": false
        },{
          \"name\": \"orchestrationEngineUrl\",
          \"value\": \"http://192.168.27.100:8004\",
          \"secure\": false
        }
      ]
    }
       " \
       http://192.168.27.100:9080/landscaper/security/cloudprovider/  | python -c \
"import json; import sys;
data=json.load(sys.stdin); print data['id']"`
fi

echo "EC2_CLOUD_PROVIDER_ID: $EC2_CLOUD_PROVIDER_ID" >> aws-setup.log

EC2_CLOUD_PROJECT_ID=`curl -s -u ucdpadmin:ucdpadmin \
http://192.168.27.100:9080/landscaper/security/cloudproject/ | python -c \
"import json; import sys;
data=json.load(sys.stdin);
for item in data:
  if item['displayName'] == 'demo@AWS':
    print item['id']"`

if [[ "$EC2_CLOUD_PROJECT_ID" == "" ]]; then

  EC2_CLOUD_PROJECT_ID=`curl -s -u ucdpadmin:ucdpadmin \
       -H 'Content-Type: application/json' \
       -X POST \
       -d "
    {
      \"name\": \"demo\",
      \"cloudProviderId\": \""$EC2_CLOUD_PROVIDER_ID"\",
      \"properties\": [
        {
          \"name\": \"functionalId\",
          \"value\": \"demo\",
          \"secure\": false
        },{
          \"name\": \"functionalPassword\",
          \"value\": \"labstack\",
          \"secure\": true
        },{
          \"name\": \"accessId\",
          \"value\": \""$AWS_ID"\",
          \"secure\": false
        },{
          \"name\": \"secretKey\",
          \"value\": \""$AWS_KEY"\",
          \"secure\": false
        },{
          \"name\": \"defaultRegion\",
          \"value\": \"RegionOne\",
          \"secure\": false
        }
      ]
    } 
    " \
       http://192.168.27.100:9080/landscaper/security/cloudproject/ | python -c \
"import json; import sys;
data=json.load(sys.stdin); print data['id']"`
fi

echo "EC2_CLOUD_PROJECT_ID: $EC2_CLOUD_PROJECT_ID" >> aws-setup.log

  keystoneUser=`curl -s -u ucdpadmin:ucdpadmin \
     -H 'Content-Type: application/json' \
     -X GET \
     http://192.168.27.100:9080/landscaper/security/user/ | python -c \
"import json; import sys;
data=json.load(sys.stdin);
for item in data:
  if item['name'] == 'demo':
    print item['id']"`

  osDemoTeam=`curl -s -u ucdpadmin:ucdpadmin \
     -H 'Content-Type: application/json' \
     -X GET \
     http://192.168.27.100:9080/landscaper/security/team/ | python -c \
"import json; import sys;
data=json.load(sys.stdin);
for item in data:
  if item['name'] == 'demo':
    print item['id']"`

  # find OpenStack cloud provider
  osCloudProvider=`curl -s -u ucdpadmin:ucdpadmin \
     -H 'Content-Type: application/json' \
     -X GET \
     http://192.168.27.100:9080/landscaper/security/cloudprovider/ | python -c \
"import json; import sys;
data=json.load(sys.stdin);
for item in data:
  if item['name'] == 'OpenStack':
    print item['id']"`

  # find 'demo' cloud project under the OpenStack cloud provider
  osCloudProject=`curl -s -u ucdpadmin:ucdpadmin \
     -H 'Content-Type: application/json' \
     -X GET \
     http://192.168.27.100:9080/landscaper/security/cloudprovider/$osCloudProvider/projects | python -c \
"import json; import sys;
data=json.load(sys.stdin);
for item in data:
  if item['name'] == 'demo':
    print item['id']"`

  curl -s -u ucdpadmin:ucdpadmin \
     -H 'Content-Type: application/json' \
     -X PUT \
     -d "
  {
    \"name\": \"demo\",
    \"roleMappings\": 
    [
      {
        \"user\": \""$keystoneUser"\",
        \"role\": \"00000000-0000-0000-0000-000000000004\"
      },
      {
        \"user\": \""$keystoneUser"\",
        \"role\": \"00000000-0000-0000-0000-000000000005\"
      },
      {
        \"user\": \""$keystoneUser"\",
        \"role\": \"00000000-0000-0000-0000-000000000301\"
      },
      {
        \"user\": \""$keystoneUser"\",
        \"role\": \"00000000-0000-0000-0000-000000000302\"
      },
      {
        \"user\": \""$keystoneUser"\",
        \"role\": \"00000000-0000-0000-0000-000000000303\"
      }
    ],
    \"resources\": [],
    \"cloud_projects\": [
      \""$osCloudProject"\",
      \""$EC2_CLOUD_PROJECT_ID"\"
    ]
  }
  " \
  http://192.168.27.100:9080/landscaper/security/team/$osDemoTeam

echo "REGION: $AWS_REGION" >> aws-setup.log
echo "VPC: $VPC_ID" >> aws-setup.log
echo "SUBNET: $SUBNET_ID" >> aws-setup.log
echo "AMI: $UBUNTU_TRUSTY_AMI" >> aws-setup.log
echo "UCD AGENT RELAY INSTANCE ID: $UCD_AGENT_RELAY_INSTANCE_ID" >> aws-setup.log
echo "UCD AGENT RELAY PUBLIC HOST: http://$UCD_AGENT_RELAY_PUBLIC_HOST" >> aws-setup.log
echo "UCD AGENT RELAY PRIVATE HOST: http://$UCD_AGENT_RELAY_PRIVATE_HOST" >> aws-setup.log

rm -f ./aws-shutdown.sh
cat >> ./aws-shutdown.sh <<EOF
#!/bin/bash

# terminates the UCD Agent Relay on AWS
# this script is dynamically created everytime you run './aws-setup.sh' and
# cannot be used to shutdown anything other than the instance that was started
# with the last execution of the './aws-setup.sh' script
echo "waiting for Agent Relay instance to shutdown on AWS in VPC $VPC_ID..."
echo "(this will take a few minutes please be patient)"
aws ec2 terminate-instances --instance-ids $UCD_AGENT_RELAY_INSTANCE_ID &>>aws-shutdown.log
i=0
while [ $i -lt 240 ]
do
  sleep 10
  AWS_STATUS=`aws ec2 describe-instance-status --instance-ids $UCD_AGENT_RELAY_INSTANCE_ID --query 'InstanceStatuses[0].[InstanceStatus]' | grep Status | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $2}'`
  if [[ "$AWS_STATUS" == "terminated" ]]; then
    i=300
  fi
  i=$[$i+10]
  printf "."
done
echo "done"
EOF

chmod 755 ./aws-shutdown.sh

echo " "
echo " "
echo "#######################################################################"
echo "This UCDP image is now configured to use Amazon Web Services!"
echo "    **** You will need to run this command each time you ****"
echo "    **** restart this image and want to deploy to AWS.   ****"
echo " "
echo "You must use the following parameters when provisioning from UCDP"
echo "to enable the UCD Agent's to talk to the UCD server on this image"
echo " "
echo "AGENT RELAY PUBLIC HOST: http://$UCD_AGENT_RELAY_PUBLIC_HOST"
#echo "AGENT RELAY PRIVATE HOST: http://$UCD_AGENT_RELAY_PRIVATE_HOST"
echo " "
echo "Run the following command to terminate the Agent Relay instance on AWS:"
echo " "
echo "./aws-shutdown.sh"
echo " "
echo "#######################################################################"
echo " "
echo " "
