require_relative "nginx/version"
require "testcontainers"

module Testcontainers
  # NginxContainer class is used to manage containers that run an NGINX server
  class NginxContainer < ::Testcontainers::DockerContainer
    # Default port used by the container
    NGINX_DEFAULT_PORT = 80

    # Default image used by the container
    NGINX_DEFAULT_IMAGE = "nginx:latest"

    # Initializes a new instance of NginxContainer
    #
    # @param image [String] the image to use
    # @param port [String] the port to use
    # @param kwargs [Hash] the options to pass to the container. See {DockerContainer#initialize}
    # @return [NginxContainer] a new instance of NginxContainer
    def initialize(image = NGINX_DEFAULT_IMAGE, port: nil, **kwargs)
      super(image, **kwargs)
      add_wait_for(:logs, /start worker process/) unless wait_for_user_defined?
    end

    # Starts the container
    #
    # @return [NginxContainer] self
    def start
      with_exposed_ports(port)
      super
    end

    # Returns the port used by the container
    #
    # @return [Integer] the port used by the container
    def port
      NGINX_DEFAULT_PORT
    end

    # Returns the server url (e.g. http://host:port)
    #
    # @param protocol [String] the protocol to use in the string (default: "http")
    # @return [String] the server url
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def server_url(protocol: "http")
      "#{protocol}://#{host}:#{mapped_port(port)}"
    end
  end
end
