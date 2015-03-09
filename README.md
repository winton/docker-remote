# DockerRemote

Wrapper for the Docker remote API and CLI.

## Usage

	DockerRemote = require("docker-remote")

	var container = {
		name:  "sidekick",
		build: "bin/build",
		run:   "bin/sidekick",
		env:   { ENV: "production" },
		git:   "git@github.com:winton/sidekick.git#release",
		repo:  "quay.io/winton/sidekick"
	};

	var args = new DockerRemote.Args(container);
	args.cliParams(); // parameters for CLI
	args.apiParams(); // parameters for Docker Remote API

	var container = new DockerRemote.Container(container);
	container.run(); // run container through remote API
	container.rm();  // remove container throught remote API

	var image = new DockerRemote.Image(container);
	image.build();  // build image through CLI
	image.create(); // download image through remote API

## Options

The container object has the following possible keys:

* `build` - The command to run within the Docker container after building the image, before pushing (optional).
* `env` - Object containing environmental variables (optional).
* `git` - A git repository URL string (optional).
* `name` - The name of the container (required).
* `ports` - An array of port strings in "[host-port]:[container-port]" format (optional).
* `repo` - The Docker repository to push to on build (optional).
* `run` - The command to run within the Docker container (optional).
* `tags` - An array of tags to use when building the image
* `volumes` - An array of volume strings in "[host-dir]:[container-dir]:[rw|ro]" format (optional).

## Dev setup

	npm install

## Docs

	node_modules/.bin/codo lib
	open doc/index.html
