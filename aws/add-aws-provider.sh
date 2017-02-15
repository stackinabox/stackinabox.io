#!/bin/bash

mkdir -p ~/.aws
rm -f ~/.aws/config
cat >> ~/.aws/config <<EOF
[default]
output = json
region = ap-southeast-2
EOF

# install AWS command line tools
sudo pip install awscli &>> aws-setup.log

echo " "
echo " "
echo "#######################################################################"
echo "   This script will add an AWS provider to this"
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
echo "#######################################################################"
echo " "
echo " "
#Uncomment this if ~/.aws/credentials has not been created
aws configure

AWS_ID=`cat ~/.aws/credentials | grep aws_access_key_id | head -1 | tr -s \ | cut -f 2 -d=`
AWS_KEY=`cat ~/.aws/credentials | grep aws_secret_access_key | head -1 | tr -s \ | cut -f 2 -d=`
AWS_REGION=`cat ~/.aws/config | grep region | head -1 | awk '{gsub(/\"/, "");gsub(/,/,""); print $3}'`


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
        },
        {
          \"name\":\"domain\",
          \"value\":\"Default\",
          \"secure\":false
        },
        {
          \"name\": \"accessId\",
          \"value\": \""$AWS_ID"\",
          \"secure\": false
        },{
          \"name\": \"secretKey\",
          \"value\": \""$AWS_KEY"\",
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
   \"cloud_project_resources\": {
     \""$osCloudProject"\" :{},
     \""$EC2_CLOUD_PROJECT_ID"\" : {}
   },
   \"cloud_projects\": [
     \""$osCloudProject"\",
     \""$EC2_CLOUD_PROJECT_ID"\"
   ]
 }
 " \
 http://192.168.27.100:9080/landscaper/security/team/$osDemoTeam

echo "done"
