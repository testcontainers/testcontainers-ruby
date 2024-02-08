require_relative "redpanda/version"
require "testcontainers"

module Testcontainers
  # RedpandaContainer class is used to manage containers that run a Redpanda
  class RedpandaContainer < ::Testcontainers::DockerContainer
    # Default port used by the container
    REDPANDA_DEFAULT_PORT = 9092

    # Default port used for schema registry
    REDPANDA_DEFAULT_SCHEMA_REGISTRY_PORT = 8081

    # Default image used by the container
    REDPANDA_DEFAULT_IMAGE = "redpandadata/redpanda:latest"

    # Default path to the startup script
    STARTUP_SCRIPT_PATH = "/testcontainers.sh"

    # Initializes a new instance of RedpandaContainer
    #
    # @param image [String] the image to use
    # @param kwargs [Hash] the options to pass to the container. See {DockerContainer#initialize}
    # @return [RedpandaContainer] a new instance of RedpandaContainer
    def initialize(image = REDPANDA_DEFAULT_IMAGE, **kwargs)
      super(image, **kwargs)
    end

    # Starts the container
    #
    # @return [RedpandaContainer] self
    def start
      with_exposed_ports(REDPANDA_DEFAULT_PORT, REDPANDA_DEFAULT_SCHEMA_REGISTRY_PORT)
      with_entrypoint(%w[/bin/sh])
      with_command(["-c", "while [ ! -f #{STARTUP_SCRIPT_PATH} ]; do sleep 0.1; done; #{STARTUP_SCRIPT_PATH}"])
      super

      # Copy the startup script to the container
      copy_file_to_container("/tmp" + STARTUP_SCRIPT_PATH, _startup_script)

      # File is copied with root owner and permissions, so we need to change them
      exec_as_root(%w[chmod 777] + ["/tmp" + STARTUP_SCRIPT_PATH])
      exec_as_root(%w[chown redpanda:redpanda] + ["/tmp" + STARTUP_SCRIPT_PATH])

      # Copy the startup script to expected location
      exec_as_root(%w[cp] + ["/tmp" + STARTUP_SCRIPT_PATH] + [STARTUP_SCRIPT_PATH])

      wait_for_logs(/Successfully started Redpanda!/)
      self
    end

    def port
      REDPANDA_DEFAULT_PORT
    end

    # Returns the Redpanda connection url (e.g. localhost:9092)
    #
    # @return [String] the Redpanda connection url
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def connection_url
      "#{host}:#{mapped_port(port)}"
    end

    def bootstrap_servers
      "PLAINTEXT://#{host}:#{mapped_port(port)}"
    end

    def schema_registry_address
      "http://#{host}:#{mapped_port(REDPANDA_DEFAULT_SCHEMA_REGISTRY_PORT)}"
    end

    private

    def _startup_script
      startup_script = StringIO.new
      startup_script.print("#!/bin/sh\n")
      startup_script.print("/usr/bin/rpk redpanda start --mode=dev-container --smp=1 --memory=1G")
      startup_script.print(" --kafka-addr PLAINTEXT://0.0.0.0:29092,OUTSIDE://0.0.0.0:9092")
      startup_script.print(" --advertise-kafka-addr PLAINTEXT://127.0.0.1:29092,OUTSIDE://#{host}:#{mapped_port(port)}")
      startup_script
    end

    def exec_as_root(cmd, options = {})
      exec(cmd, options.merge({"User" => "root"}))
    end
  end
end
