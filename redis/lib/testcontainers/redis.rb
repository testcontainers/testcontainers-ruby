require_relative "redis/version"
require "testcontainers"

module Testcontainers
  # RedisContainer class is used to manage containers that run a Redis database
  class RedisContainer < ::Testcontainers::DockerContainer
    # Default port used by the container
    REDIS_DEFAULT_PORT = 6379

    # Default image used by the container
    REDIS_DEFAULT_IMAGE = "redis:latest"

    # Initializes a new instance of RedisContainer
    #
    # @param image [String] the image to use
    # @param port [String] the port to use
    # @param kwargs [Hash] the options to pass to the container. See {DockerContainer#initialize}
    # @return [RedisContainer] a new instance of RedisContainer
    def initialize(image = REDIS_DEFAULT_IMAGE, **kwargs)
      super
      add_wait_for(:logs, /Ready to accept connections/) unless wait_for_user_defined?
    end

    # Starts the container
    #
    # @return [RedisContainer] self
    def start
      with_exposed_ports(port)
      super
    end

    # Returns the port used by the container
    #
    # @return [Integer] the port used by the container
    def port
      REDIS_DEFAULT_PORT
    end

    # Returns the Redis connection url (e.g. redis://:password@localhost:6379/0)
    #
    # @param protocol [String] the protocol to use in the string (default: "redis")
    # @return [String] the Redis connection url
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def redis_url(protocol: "redis", db: 0)
      if @password.nil? || @password.empty?
        "#{protocol}://#{host}:#{mapped_port(port)}/#{db}"
      else
        "#{protocol}://:#{password}@#{host}:#{mapped_port(port)}/#{db}"
      end
    end

    alias_method :database_url, :redis_url
  end
end
