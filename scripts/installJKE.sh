#!/bin/bash
echo adding jke demo artifacts...
sleep 120
cd
git clone https://github.com/stackinabox/docker-demo-jke.git -b dojojkeupdate
cd docker-demo-jke
docker build -t stackinabox/demo-jke:1.0 .
docker run --rm stackinabox/demo-jke:1.0 /jke/init
