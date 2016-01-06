Promise = require "bluebird"
path    = require "path"

module.exports = (DockerRemote) ->

  # Builds image from Dockerfile.
  #
  class DockerRemote.Image

    # Initializes image commands and command spawner.
    #
    # @param [Object] @container container object
    #
    constructor: (@container) ->
      DockerRemote.modifyContainer(@container)

      @api      = new DockerRemote.Api.Image(@container)
      @spawn    = DockerRemote.spawn("inherit")
      @spawnOut = DockerRemote.spawn()
      @commands =
        app_sha:   "git rev-parse HEAD"
        clone_app:
          """
          git clone -b #{@container.branch} \
            --single-branch #{@container.git} \
            .tmp/#{@container.name}
          """
        mkdir_app: "mkdir -p .tmp/#{@container.name}"
        rmrf_app:  "rm -rf .tmp/#{@container.name}"

    # Gets the sha of the app code.
    #
    # @return [Promise<String>] promise that resolves when command
    #   finishes
    #
    appSha: ->
      @spawnOut(
        @commands.app_sha
        cwd: ".tmp/#{@container.name}"
      ).then (sha) ->
        sha.substring(0,8)

    # Builds an image.
    #
    # @return [Promise<String,Number>] the output and exit code
    #
    build: ->
      props   = {}
      promise = null

      if @container.buildStart
        @container.buildStart(@container)

      if @container.dockerfile && @container.dockerfile.indexOf(".tmp/") == -1
        promise = Promise.resolve(@container.tags.shift())
      else
        promise = @rmrfApp().then(
          => @mkdirApp()
        ).then(
          => @cloneApp()
        ).then(
          => @appSha()
        )

      promise.then(
        (sha) => @buildImage(sha)
      ).then(
        => @runPostBuild(props)
      ).then(
        => @waitForFinish(props)
      ).then(
        => @commitContainer(props)
      ).then(
        => @tagContainer(props)
      ).then(
        => @pushImage(props)
      ).then(
        =>
          if @container.buildEnd
            @container.buildEnd(@container)
      )

    # Runs `docker build` on the app code.
    #
    # @param [String] tag the tag of the release
    # @return [Promise] promise that resolves when command finishes
    #
    buildImage: (tag) ->
      @container.tag = tag
      
      @buildImageCommand().then(
        (output) => @spawn(output)
      )

    # Generates the `docker build` command.
    #
    # @return [String] the docker build command
    #
    buildImageCommand: ->
      app_dir    = path.resolve @container.dockerfile
      app_dir  ||= ".tmp/#{@container.name}"
      dockerfile = "#{app_dir}/Dockerfile"
      build_args = []

      for key, value of @container.buildArgs || []
        build_args.push "--build-arg #{key}=#{value}"

      """
      docker build \
        -t #{@container.repo}:#{@container.tag} \
        #{build_args.join(" ")} \
        #{app_dir}
      """

    # Check `docker ps` for the existence of a container sha.
    #
    # @param [String] run_sha the sha of the container
    # @return [Promise] promise that resolves when command finishes
    #
    checkContainerSha: (run_sha) ->
      run_sha = run_sha.substring(0, 12)
      @spawnOut("docker ps").then(
        (output) =>
          !!output.match(///#{run_sha}\s+///g)
      )

    # Start a timer to continually check if a container finished
    # running.
    #
    # @param [String] run_sha the sha of the container
    # @param [Function] resolve the function to run once the
    #   container is found
    # @return [Number] `setTimeout` id
    #
    checkFinished: (run_sha, resolve) ->
      setTimeout(
        =>
          process.stdout.write(".")

          @checkContainerSha(run_sha).then (found) =>
            if found
              @checkFinished(run_sha, resolve)
            else
              console.log ""
              resolve()
        1*1000
      )

    # Clone the app code into `.tmp`.
    #
    # @return [Promise] promise that resolves when command finishes
    #
    cloneApp: ->
      @spawnOut(@commands.clone_app)

    # Command to commit the container generated from the post build
    # command.
    #
    # @param [String] run_sha the sha of the container
    #
    commitCommand: (run_sha) ->
      "docker commit #{run_sha} #{@container.repo}"

    # Commit the container if a post build command executed.
    #
    # @param [Object] props shared properties from `build`
    # @return [Promise] promise that resolves when command finishes
    #
    commitContainer: (props) ->
      if @container.build
        @spawnOut(@commitCommand(props.run_sha))

    # Create the Docker image if it doesn't already exist.
    #
    # @return [Promise] promise that resolves when API call finishes
    #
    create: ->
      @api.create()

    # Makes the directory to house the app code within `.tmp`.
    #
    # @return [Promise] promise that resolves when command finishes
    #
    mkdirApp: ->
      @spawnOut(@commands.mkdir_app)

    # Pushes the docker image to the registry.
    #
    # @param [Object] props shared properties from `build`
    # @return [Promise] promise that resolves when command finishes
    #
    pushImage: (props) ->
      if @container.push
        promise = @spawn(@pushImageCommand())
        for tag in @container.tags
          promise = promise.then => @spawn(@pushImageCommand(tag))

      promise

    # Generates the `docker push` command.
    #
    # @param [String] tag the tag to push
    # @return [String] the docker push command
    #
    pushImageCommand: (tag=@container.tag) ->
      "docker push #{@container.repo}:#{tag}"

    # Remove the app code in the `.tmp` directory.
    #
    # @return [Promise] promise that resolves when command finishes
    #
    rmrfApp: ->
      @spawnOut(@commands.rmrf_app)

    # Run the post build command.
    #
    # @param [Object] props shared properties from `build`
    # @return [Promise] promise that resolves when command finishes
    #
    runPostBuild: (props) ->
      container = new DockerRemote.Container(@container, "build")

      if @container.build
        container.run().then(
          (output) ->
            props.run_sha = output.id
        )

    # Generates the `docker tag` command.
    #
    # @param [String] source the source tag
    # @param [String] dest the destination tag
    # @return [String] the docker tag command
    #
    tagCommand: (source, dest) ->
      """
      docker tag -f \
        #{@container.repo}:#{source} \
        #{@container.repo}:#{dest}
      """

    # Tag the image.
    #
    # @param [Object] props shared properties from `build`
    # @return [Promise] promise that resolves when command finishes
    #
    tagContainer: (props) ->
      promise = Promise.resolve()
      for tag in @container.tags
        promise = promise.then =>
          @spawnOut(@tagCommand(@container.tag, tag))

    # Wait for post build commands to finish.
    #
    # @param [Object] props shared properties from `build`
    # @return [Promise] promise that resolves when command finishes
    #
    waitForFinish: (props) ->
      if @container.build
        process.stdout.write "Waiting for post build command to finish"

        new Promise (resolve) =>
          @checkFinished(props.run_sha, resolve)
