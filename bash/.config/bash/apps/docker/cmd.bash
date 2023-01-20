# dockerize launches a containerized dev env of the PWD
dockerize () {
  local docker_image='ghcr.io/exbotanical/docker-dev-env:latest'

  echo -e "Building a fresh dev environment as an ephemeral container in $(pwd)...\n"
  docker run --rm -it -v "$(pwd):/ephemeral" "$docker_image"
}

# docker_intermediate_prune prunes all dangling intermediate images
docker_intermediate_prune () {
  docker rmi $(docker images -a | grep '<none>' | awk '{ print $3 }')
}
