#!/bin/bash

#ssh -i /vagrant/images/aws.pem -f -N -R *:20080:192.168.27.100:8081 ubuntu@54.165.178.106
set -o errexit

key=${1:-~/default.pem}
pubhost=${2:-localhost}
privhost=${3:-localhost}
user=${4:-ubuntu}

# default values match UCD Agent Relay default port values
jmsPort=${5:-7916}
httpPort=${6:-20080}
codestationPort=${7:-20081}

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
-i $key -tt $user@$pubhost &>>.log <<EOF

echo "\
GatewayPorts clientspecified" | sudo tee -a /etc/ssh/sshd_config
sudo initctl restart ssh

exit
EOF

sudo ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
-i $key -f -N -R $privhost:$httpPort:192.168.27.100:$httpPort \
-R $privhost:$codestationPort:192.168.27.100:$codestationPort \
-R $privhost:$jmsPort:192.168.27.100:$jmsPort $user@$pubhost &>>tunnel.log
