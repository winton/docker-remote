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
    if container.git
      [ container.git, container.branch ] = container.git.split("#")

    container.branch  ||= "master"
    container.ports   ||= []
    container.tags    ||= [ "latest" ]
    container.tag     ||= container.tags[0]
    container.volumes ||= []

    container

  @spawn: (stdio="pipe") ->
    spawn = new DockerRemote.Spawn(stdio: stdio)
    spawn.spawn.bind(spawn)

require("./docker_remote/api")(DockerRemote)
require("./docker_remote/args")(DockerRemote)
require("./docker_remote/container")(DockerRemote)
require("./docker_remote/image")(DockerRemote)
require("./docker_remote/spawn")(DockerRemote)

module.exports = DockerRemote
