#!/bin/bash
echo Setting up AWS Provider in UCD Designer...
cd
wget https://github.com/stackinabox/stackinabox.io/raw/interconnect2017/aws/add-aws-provider.sh
chmod +x add-aws-provider.sh
mkdir -p ~/.aws
cat > ~/.aws/credentials <<EOF
[default]
aws_access_key_id=EXAMPLE
aws_secret_access_key=EXAMPLE
EOF
./add-aws-provider.sh
