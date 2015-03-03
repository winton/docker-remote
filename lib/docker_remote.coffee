# Provides libraries for running Docker remote API calls.
#
class DockerRemote

  # Changes the container object to make consumption by subclasses
  # easier.
  #
  # @param [Object] container container object
  # @return [Object] container container object
  #
  @modifyContainer: (container) ->
    [ container.git, container.branch ] = container.git.split("#")

    container.branch  ||= "master"
    container.ports   ||= []
    container.volumes ||= []

    container

require("./docker_remote/api")(DockerRemote)
require("./docker_remote/args")(DockerRemote)
require("./docker_remote/container")(DockerRemote)
require("./docker_remote/image")(DockerRemote)

module.exports = DockerRemote
