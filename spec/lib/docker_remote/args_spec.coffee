_ = require "lodash"
Promise      = require("bluebird")
DockerRemote = require("../../../lib/docker_remote")

describe "Sidekick", ->

  beforeAll ->
    @subject = new DockerRemote.Args(
      name:    "test"
      git:     "git@github.com:winton/docker-remote.git"
      repo:    "quay.io/winton/docker-remote"
      ports:   [ 80, "22:22", "8889:8889/udp", "127.0.0.1::8899" ]
      network: "testnet"
      env:
        DOCKER_SOCKET_PATH: "/var/run"
        ENV: "production"
    )

  describe "cliParams", ->

    beforeEach ->
      @subject = @subject.cliParams()

    it "generates CLI parameters", ->
      expect(@subject).toEqual [
        '--name'
        'test'
        '-e'
        'DOCKER_SOCKET_PATH=/var/run'
        '-e'
        'ENV=production'
        '-p'
        '80/tcp'
        '-p'
        '22:22/tcp'
        '-p'
        '8889:8889/udp'
        '-p'
        '127.0.0.1::8899/tcp'
        '--net=testnet'
        'quay.io/winton/docker-remote:latest'
      ]

  describe "apiParams", ->

    beforeEach ->
      @subject = @subject.apiParams()

    it "generates API parameters", ->
      expect(@subject).toEqual
        name: 'test'
        Cmd: undefined
        Image: 'quay.io/winton/docker-remote:latest'
        Env: [
          'DOCKER_SOCKET_PATH=/var/run'
          'ENV=production'
        ]
        HostConfig:
          Binds: []
          Links: []
          VolumesFrom: []
          NetworkMode: "testnet"
          PortBindings:
            "22/tcp":   [HostPort: "22"]
            "8889/udp": [HostPort: "8889"]
        ExposedPorts:
          "80/tcp":   {}
          "22/tcp":   {}
          "8889/udp": {}
          "8899/tcp": {}
        Volumes: {}
