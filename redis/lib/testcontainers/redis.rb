require_relative "redis/version"
require "testcontainers"

module Testcontainers
  # RedisContainer class is used to manage containers that run a Redis database
  #
  # @attr_reader [String] port used by the container
  # @attr_reader [String] password used by the container
  class RedisContainer < ::Testcontainers::DockerContainer
    # Default port used by the container
    REDIS_DEFAULT_PORT = 6379

    # Default image used by the container
    REDIS_DEFAULT_IMAGE = "redis:latest"

    attr_reader :port, :password

    # Initializes a new instance of RedisContainer
    #
    # @param image [String] the image to use
    # @param port [String] the port to use
    # @param kwargs [Hash] the options to pass to the container. See {DockerContainer#initialize}
    # @return [RedisContainer] a new instance of RedisContainer
    def initialize(image = REDIS_DEFAULT_IMAGE, port: nil, **kwargs)
      super(image, **kwargs)
      @port = port || ENV.fetch("REDIS_PORT", REDIS_DEFAULT_PORT)
      @password = password || ENV.fetch("REDIS_PASSWORD", nil)
    end

    # Starts the container
    #
    # @return [RedisContainer] self
    def start
      with_exposed_ports(@port)
      _configure
      super
    end

    # Sets the password to use
    #
    # @param password [String] the password to use
    # @return [RedisContainer] self
    def with_password(password)
      @password = password
      self
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

    private

    def _configure
      add_env("REDIS_PASSWORD", @password) unless @password.nil? || @password.empty?
    end
  end
end
