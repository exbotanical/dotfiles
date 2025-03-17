#!/usr/bin/env bash
APP_NAME='dotfiles'

docker container ls -a | grep $APP_NAME | awk '{ print $1 }' | xargs docker rm
docker image ls | grep $APP_NAME | awk '{ print $3 }' | xargs docker rmi
docker build -f Dockerfile.dev -t $APP_NAME .
docker run -it --entrypoint /bin/bash -v $(pwd):/usr/app $APP_NAME
