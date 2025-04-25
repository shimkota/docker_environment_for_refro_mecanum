#!/bin/bash
 
cd `dirname $0`

IMAGE="kjm/ros/humble:latest"

docker build -t ${IMAGE} ./
