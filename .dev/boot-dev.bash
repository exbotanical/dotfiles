#!/usr/bin/env bash
RootDir="$(dirname "$(readlink -f $BASH_SOURCE)")"
AppName='dotfiles'

docker container ls -a | grep $AppName | awk '{ print $1 }' | xargs docker rm
docker image ls | grep $AppName | awk '{ print $3 }' | xargs docker rmi
docker build -f $RootDir/Dockerfile.dev -t $AppName .
docker run -it --entrypoint /bin/bash -v $(pwd):/usr/app $AppName
