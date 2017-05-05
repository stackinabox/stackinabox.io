#!/bin/bash

echo "Creating UrbanCode Enterprise Platform Services"

echo "`ls -la`"
cd ./compose/urbancode
docker-compose -f bluemix-compose.yml -p UrbanCodePlatform up -d
