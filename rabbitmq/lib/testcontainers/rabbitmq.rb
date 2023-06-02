require_relative "rabbitmq/version"
require "testcontainers"
require "uri"

module Testcontainers
  # RabbitmqContainer class is used to manage containers that runs a RabbitMQ message broker
  #
  # @attr_reader [String] username used by the container
  # @attr_reader [String] password used by the container
  # @attr_reader [String] database used by the container
  class RabbitmqContainer < ::Testcontainers::DockerContainer
    # Default ports used by the container
    RABBITMQ_QUEUE_DEFAULT_PORT = 5672
    RABBITMQ_PLUGINS_DEFAULT_PORT = 15672

    # Default image used by the container
    RABBITMQ_DEFAULT_IMAGE = "rabbitmq:latest"
    RABBITMQ_DEFAULT_USER = "test"
    RABBITMQ_DEFAULT_PASS = "test"
    RABBITMQ_DEFAULT_VHOST = "test"

    attr_reader :username, :password

    # Initializes a new instance of RabbitMQContainer
    #
    #  @param image [String] the image to use
    #  @param username [String] the username to use
    #  @param password [String] the password to use
    #  @param port [String] the port to use
    #  @param kwargs [Hash] the options to pass to the container. See {DockerContainer#initialize}
    #  @return [RabbitmqContainer] a new instance of RabbitmqContainer
    def initialize(image = RABBITMQ_DEFAULT_IMAGE, username: nil, password: nil, vhost: nil, **kwargs)
      super(image, **kwargs)
      @username = username || ENV.fetch("RABBITMQ_USER", RABBITMQ_DEFAULT_USER)
      @password = password || ENV.fetch("RABBITMQ_PASSWORD", RABBITMQ_DEFAULT_PASS)
      @vhost = vhost || ENV.fetch("RABBITMQ_VHOST", RABBITMQ_DEFAULT_VHOST)
      @wait_for ||= add_wait_for(:logs, //)
    end

    # Starts the container
    #
    # @return [RabbitmqContainer] self
    def start
      with_exposed_ports([queue_port, plugins_port])
      _configure
      super
    end

    # Returns the port used to connect to the container to enqueue messages
    #
    # @return [Integer] the port used by the container
    def queue_port
      RABBITMQ_QUEUE_DEFAULT_PORT
    end

    # Returns the port used to connect to the container to add_plugins
    #
    # @return [Integer] the port used by the container
    def plugins_port
      RABBITMQ_PLUGINS_DEFAULT_PORT
    end

    # Returns the rabbitmq url (e.g. mysql://user:password@host:port/database)
    #
    # @param protocol [String] the protocol to use in the string (default: "mysql")
    # @param database [String] the database to use in the string (default: @database)
    # @param options [Hash] the options to use in the query string (default: {})
    # @return [String] the rabbitmq url
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def rabbitmq_url(protocol: "amqp", username: nil, password: nil, vhost: nil)
      username ||= @username
      password ||= @password
      vhost ||= @vhost

      # amqp://user:pass@host:10000/vhost
      "#{protocol}://#{username}:#{password}@#{host}:#{mapped_port(queue_port)}/#{vhost}"
    end

    # Sets the vhost to use
    #
    # @param vhost [String] the vhost to use
    # @return [RabbitmqContainer] self
    def with_vhost(vhost)
      @vhost = vhost
      self
    end

    # Sets the username to use
    #
    # @param username [String] the username to use
    # @return [RabbitmqContainer] self
    def with_username(username)
      @username = username
      self
    end

    # Sets the password to use
    #
    # @param password [String] the password to use
    # @return [RabbitmqContainer] self
    def with_password(password)
      @password = password
      self
    end

    # Returns the container's first mapped port used to enqueue messages..
    #
    # @return [Integer] The container's first mapped port.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    def first_queue_mapped_port
      raise ContainerNotStartedError unless @_container
      mapped_port(queue_port)
    end

    private

    def _configure
      add_env("RABBITMQ_DEFAULT_USER", @username)
      add_env("RABBITMQ_DEFAULT_PASS", @password)
      add_env("RABBITMQ_DEFAULT_VHOST", @vhost) if @vhost
    end
  end
end
