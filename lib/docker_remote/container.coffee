Promise = require "bluebird"

module.exports = (DockerRemote) -> 

  # List, run, and remove Docker containers.
  #
  class DockerRemote.Container

    # Instantiate a `DockerRemote.Api.Container` instance.
    #
    # @param [Object] @container container configuration object
    # @param [String] @run_key the container key to use for the
    #   command (typically "run" or "build")
    #
    constructor: (@container, @run_key="run") ->
      DockerRemote.modifyContainer(@container)
      
      @api = new DockerRemote.Api.Container(@container)

    # List Docker containers.
    #
    # @param [Object] options parameter to `DockerRemote.Api.Container#list`
    # @return [Array<Object>]
    #
    ps: (options) ->
      @api.list(options)

    # Run a Docker container.
    #
    # @param [Object] options parameter to `DockerRemote.Args`
    # @return [Promise<Object>]
    #
    run: (options) ->
      args = new DockerRemote.Args(@container, @run_key)

      @rm().then(=>
        @api.create(
          args.apiParams()
        )
      ).then(
        (output) =>
          Promise.props(
            start: @api.start()
            id:    output.id
          )
      )

    # Remove a Docker container.
    #
    # @param [Object] options parameter to `DockerRemote.Api.Container#remove`
    #
    rm: (options={}) ->
      if options.force == undefined
        options.force = true

      @api.remove(options)
