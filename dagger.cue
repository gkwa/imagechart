package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
	"universe.dagger.io/docker/cli"
)

#RedisTLS: {
	app:   dagger.#FS
	image: build.output

	build: docker.#Build & {
		steps: [
			docker.#Pull & {
				source: "ubuntu:kinetic"
			},
			docker.#Run & {
				command: {
					name: "apt"
					args: ["update"]
				}
			},
			docker.#Run & {
				command: {
					name: "apt"
					args: ["-qy", "install", "redis", "tcl", "tcl-tls", "libssl-dev", "libjemalloc-dev"]
				}
			},
			docker.#Run & {
				command: {
					name: "apt"
					args: ["-qy", "install", "git", "pkg-config", "build-essential"]
				}
			},
			docker.#Run & {
				command: {
					name: "git"
					args: ["clone", "--depth", "1", "https://github.com/redis/redis.git", "/tmp/redis"]
				}
			},
			docker.#Run & {
				workdir: "/tmp/redis"
				command: {
					name: "make"
					args: ["distclean"]
				}
			},
			docker.#Run & {
				workdir: "/tmp/redis"
				command: {
					name: "make"
					args: ["BUILD_TLS=yes"]
				}
			},
			docker.#Run & {
				workdir: "/tmp/redis"
				command: {
					name: "make"
					args: ["test"]
				}
			},
			docker.#Run & {
				command: {
					name: "apt"
					args: ["clean"]
				}
			},
			docker.#Run & {
				command: {
					name: "rm"
					args: ["-rf", "/tmp/redis"]
				}
			},
		]
	}
}

dagger.#Plan & {
	actions: {
		buildImages: redisTLSBuild: #RedisTLS & {
			app: client.filesystem.".".read.contents
		}

		load: redisbuildImageToLocalDockerRepo: cli.#Load & {
			image: buildImages.redisTLSBuild.image
			host:  client.network."unix:///var/run/docker.sock".connect
			tag:   "redistls-dagger:latest"
		}
	}

	client: {
		env: DEBIAN_FRONTEND: "noninteractive"
		network: "unix:///var/run/docker.sock": connect: dagger.#Socket
		filesystem: ".": read: contents: dagger.#FS
	}
}
