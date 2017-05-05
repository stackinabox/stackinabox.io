#!/bin/bash

echo "Download Docker CLI"
curl -L https://github.com/docker/compose/releases/download/1.8.0-rc2/docker-compose-`uname -s`-`uname -m` > /tmp/docker-compose
chmod +x /tmp/docker-compose

export PATH="/tmp/docker-compose:$PATH"

if [ -n "$DEBUG" ]; then
  docker --version
  docker-compose --version
fi
