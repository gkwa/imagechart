package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
)

#RedisBuild: {
	app: dagger.#FS

	image: _build.output

	_build: docker.#Build & {
		steps: [
			docker.#Pull & {
				source: "ubuntu:20.04"
			},
			docker.#Copy & {
				contents: app
				dest:     "/app"
			},
			docker.#Run & {
				command: {
					name: "apt-get"
					args: ["-qq", "update"]
				}
			},
			docker.#Run & {
				command: {
					name: "apt-get"
					args: ["-qy", "install", "redis", "tcl-tls"]
				}
			},
		]
	}
}

dagger.#Plan & {
	client: filesystem: "./src": read: contents: dagger.#FS

	actions: build: #RedisBuild & {
		app: client.filesystem."./src".read.contents
	}
}
