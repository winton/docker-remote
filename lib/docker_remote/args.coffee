_    = require "lodash"
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
      Env:   @envs()
      Image: @image()
      HostConfig:
        Binds: @binds()
        Links: @container.links
        PortBindings: @apiPortBindings()
        VolumesFrom:  @container.vfrom
        NetworkMode: @container.network if @container.network
      ExposedPorts: @apiExposedPorts()
      Volumes: @volumes()

    # Generate binds option (which local directories to mount
    # within the container).
    #
    # @return [Object]
    #
    binds: (empty_volumes=false) ->
      _.compact @container.volumes.map (volume) ->
        [ host, container ] = volume.split(":")
        host = path.resolve(host)
        if container && !empty_volumes
          "#{host}:#{container}"
        else if !container && !empty_volumes
          null
        else
          host

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

      for vol in @container.vfrom
        params.push("--volumes-from")
        params.push(vol)

      for {ip, client_port, host_port, proto} in @ports()
        params.push "-p"
        params.push(
          if ip?
            "#{[ip, host_port, client_port].join(":")}/#{proto}"
          else
            "#{[host_port, client_port].filter((v) -> v).join(":")}/#{proto}"
        )

      params.push "--net=#{@container.network}" if @container.network

      params.push(@image())

      if @container[@run_key] && !options.options_only
        run = @container[@run_key].slice()
        run[2] = "\"#{run[2]}\"" if "#{run[0..1]}" == "#{[ "sh", "-c" ]}"
        params = params.concat(run)

      params

    # Generate environment variables to be passed to the container.
    #
    # @return [Array<String>] an array of strings in "VAR=var" format
    #
    envs: ->
      for key, value of @container.env
        "#{key.toUpperCase()}=#{value}"

    image: ->
      "#{@container.repo}:#{@container.tags[0] || "latest"}"

    # Generate an object that specifies the ports configuration
    #
    # @ return [Object] an array of objects representing the port config
    #
    ports: ->
      for port in @container.ports
        [fragments..., last] = "#{port}".split(":")
        [last, proto ]       = last.split("/")
        fragments            = fragments.concat [last]
        proto              ||= "tcp"

        switch fragments.length
          when 1
            ip: null, host_port: null, client_port: port, proto: proto
          when 2
            ip: null
            host_port: fragments[0]
            client_port: fragments[1]
            proto: proto
          when 3
            ip: fragments[0]
            host_port: fragments[1]
            client_port: fragments[2]
            proto: proto

    # Generates the PortBindings payload for API calls
    #
    # @return [Objects] an array adhering to the latest json representation
    apiPortBindings: ->
      _.fromPairs(
        for {ip, host_port, client_port, proto} in @ports() when host_port? and host_port != ""
          ["#{client_port}/#{proto}", [HostPort: host_port]]
      )

    # Generates the ExposedPorts payload for API calls
    #
    # @return [Objects] an array adhering to the latest json representation
    apiExposedPorts: ->
      _.fromPairs(
        for {ip, host_port, client_port, proto} in @ports()
          ["#{client_port}/#{proto}", {}]
      )

    # Generate an object for the `Volumes` option of the Docker API.
    #
    # @return [Object]
    #
    volumes: ->
      obj = {}
      for volume in @binds(true)
        obj[volume] = {}
      obj
