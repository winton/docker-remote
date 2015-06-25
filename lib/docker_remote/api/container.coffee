Promise = require("bluebird")

module.exports = (DockerRemote) ->

  # Create, find, list, remove, and start Docker containers.
  #
  class DockerRemote.Api.Container

    # Initialize `DockerRemote.Api.Client` and a `Dockerode`
    # container instance.
    #
    constructor: (@container) ->
      @client = new DockerRemote.Api.Client()

    # Retrieve the Dockerode container API object.
    #
    # @return [Promise<Container>]
    #
    containerApi: ->
      @find((container) =>
        container.Names && container.Names.indexOf("/#{@container.name}") > -1
      ).then (container) =>
        @client.getContainer(container.Id) if container

    # Create a Docker container.
    #
    # @param [Object] params parameters to `DockerRemote.Api.Client#createContainer`
    # @return [Promise<Container>]
    #
    create: (params) ->
      Promise.resolve(
        @client.createContainer(params)
      )

    # Find a Docker container.
    # 
    # @param [Function] fn callback
    # @return [Promise<Container>]
    #
    find: (fn) ->
      @client.listContainers(all: 1).then (containers) ->
        for container in containers
          return container if fn(container)
        null

    # List all Docker containers.
    #
    # @param [Object] params parameters to `DockerRemote.Api.Client#listContainers`
    # @return [Array<Object>]
    #
    list: (options) -> @client.listContainers(options)

    # Remove a Docker container.
    # 
    # @param [Object] options parameters to `Dockerode::Container#remove`
    # @return [Object] response from `Dockerode::Container#remove`
    #
    remove: (options) ->
      @containerApi().then (container) ->
        if container
          Promise.promisify(container.remove, container)(options)

    # Start a Docker container.
    #
    # @param [Container] container a `Dockerode::Container` object
    # @return [Object] response from `Dockerode::Container#start`
    #
    start: ->
      @containerApi().then (container) ->
        if container
          Promise.promisify(container.start, container)()
