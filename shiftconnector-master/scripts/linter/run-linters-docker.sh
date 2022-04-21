#!/bin/bash
set -euo pipefail
# This script just builds and runs a docker image and then runs the linter scripts 
# if you have docker installed, this should build, run, init and execute the linters (as per the pipeline) against this repo
# NB: the project folder should be mounted in /mount in the container

IMAGE=cfn-linter

docker build -t $IMAGE scripts/linter

# Not sure why doing this?
if [ $OSTYPE = "msys" ]; then
  CURRENT_PATH=$(pwd -W)
  winpty docker run -it --rm -v "$CURRENT_PATH:/mount" $IMAGE bash -c "cd /mount && scripts/linter/run-linters.sh"
else
  CURRENT_PATH=$(pwd)
  docker run -it --rm -v "$CURRENT_PATH:/mount" $IMAGE bash -c "cd /mount && scripts/linter/run-linters.sh"
fi