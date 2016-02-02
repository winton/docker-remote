module.exports = (DockerRemote) ->

  # Namespace for DockerRemote.Api classes.
  #
  class DockerRemote.Api

  require("./api/client")(DockerRemote)
  require("./api/container")(DockerRemote)
  require("./api/image")(DockerRemote)
