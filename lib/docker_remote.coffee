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
    container.links   ||= []
    container.ports   ||= []
    container.tags    ||= []
    container.volumes ||= []

    container

  # Helps subclasses run system commands.
  #
  # @param [String] stdio "inherit" or "pipe"
  #
  @spawn: (stdio="pipe") ->
    spawn = new DockerRemote.Spawn(stdio: stdio)
    spawn.spawn.bind(spawn)

require("./docker_remote/api")(DockerRemote)
require("./docker_remote/args")(DockerRemote)
require("./docker_remote/container")(DockerRemote)
require("./docker_remote/image")(DockerRemote)
require("./docker_remote/spawn")(DockerRemote)

module.exports = DockerRemote
