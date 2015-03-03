Promise      = require("bluebird")
DockerRemote = require("../../../lib/docker_remote")

describe "Sidekick", ->

  beforeAll ->
    @subject = new DockerRemote.Args(
      name: "test"
      env:
        DOCKER_SOCKET_PATH: "/var/run"
        ENV: "production"
      git:  "git@github.com:winton/docker-remote.git"
      repo: "quay.io/winton/docker-remote"
    )

  describe "cliParams", ->

    beforeEach ->
      @subject = @subject.cliParams()

    it "generates CLI parameters", ->
      expect(@subject).toEqual([
        '--name',
        'test',
        '-e',
        'DOCKER_SOCKET_PATH=/var/run',
        '-e',
        'ENV=production',
        'quay.io/winton/docker-remote:latest'
      ])

  describe "apiParams", ->

    beforeEach ->
      @subject = @subject.apiParams()

    it "generates API parameters", ->
      expect(@subject).toEqual(
        name: 'test'
        Cmd: undefined
        Image: 'quay.io/winton/docker-remote:latest'
        Env: [
          'DOCKER_SOCKET_PATH=/var/run'
          'ENV=production'
        ]
        HostConfig:
          Binds: []
          PortBindings: {}
        ExposedPorts: {}
      )  
