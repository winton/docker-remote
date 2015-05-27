path = require "path"

module.exports = (DockerRemote) -> 

  # Generates arguments for Docker CLI and remote API.
  #
  class DockerRemote.Args

    # Initializes `@container`.
    #
    # @param [Object] @container container object
    # @param [String] @run_key the container key to use for the
    #  command (typically "run" or "build")
    #
    constructor: (@container, @run_key="run") ->
      DockerRemote.modifyContainer(@container)

    # Generates parameters for a Docker remote API call.
    #
    # @return [Object]
    #
    apiParams: ->
      name:  @container.name
      Cmd:   @container[@run_key]
      Image: @image()
      Env:   @envs()
      HostConfig:
        Binds: @binds()
        Links: @container.links
        PortBindings: @portBindings()
      ExposedPorts: @exposedPorts()

    # Generate binds option (which local directories to mount
    # within the container).
    #
    # @return [Object]
    #
    binds: ->
      @container.volumes.map (volume) ->
        [ host, container ] = volume.split(":")
        host = path.resolve(host)
        "#{host}:#{container}"

    # Generates parameters for a Docker CLI call.
    #
    # @return [Object]
    #
    cliParams: (options={}) ->
      params = [ "--name", @container.name ]

      for env in @envs()
        params.push("-e")
        params.push(env)

      for link in @container.links
        params.push("-l")
        params.push(link)

      for bind in @binds()
        params.push("-v")
        params.push(bind)

      for client_port, host_ports of @portBindings()
        for host_port in host_ports
          params.push("-p")
          params.push(
            "#{host_port.HostPort}:#{client_port.split("/")[0]}"
          )

      params.push(@image())

      if @container[@run_key]
        run = @container[@run_key].slice()
        run[2] = "\"#{run[2]}\"" if "#{run[0..1]}" == "#{[ "sh", "-c" ]}"
        params = params.concat(run)

      params

    # Generate environment variables to be passed to the container.
    #
    # @return [Array<String>] an array of strings in "VAR=var" format
    #
    envs: ->
      envs = []

      for key, value of @container.env
        envs.push("#{key}=#{value}")

      envs

    # Generate an object for the `ExposedPorts` option of the Docker
    # API.
    #
    # @return [Object]
    #
    exposedPorts: ->
      ports = @portBindings(@name)
      ports[key] = {} for key, value of ports
      ports

    image: ->
      "#{@container.repo}:#{@container.tags[0]}"

    # Generate an object for the `PortBindings` option of the
    # Docker API.
    #
    # @return [Object]
    #
    portBindings: ->
      ports = {}
      for port in @container.ports
        [ host_port, container_port ]  = port.split(":")
        ports["#{container_port}/tcp"] = [ HostPort: host_port ]
      ports
