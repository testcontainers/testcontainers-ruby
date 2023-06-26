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
    RABBITMQ_MGMT_UI_DEFAULT_PORT = 15672

    # Default image used by the container
    # To have the management plugin enabled, use the image with the tag "management"
    RABBITMQ_DEFAULT_IMAGE = "rabbitmq:latest"

    # Default credentials used by the container
    RABBITMQ_DEFAULT_USER = "rabbitmq"
    RABBITMQ_DEFAULT_PASS = "rabbitmq"

    # Default vhost used by the container
    RABBITMQ_DEFAULT_VHOST = "/"

    attr_reader :username, :password, :vhost

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
      @healthcheck ||= add_healthcheck(_default_healthcheck_options)
      @wait_for ||= add_wait_for(:healthcheck)
    end

    # Starts the container
    #
    # @return [RabbitmqContainer] self
    def start
      with_exposed_ports([port, management_ui_port])
      _configure
      super
    end

    # Returns the port used to connect to the container queue
    #
    # @return [Integer] the port used by the container
    def port
      RABBITMQ_QUEUE_DEFAULT_PORT
    end

    # Returns the port used to connect to the container management UI
    # This is available only if an image with the management plugin enabled is used
    #
    # @return [Integer] the port used by the container
    def management_ui_port
      RABBITMQ_MGMT_UI_DEFAULT_PORT
    end

    # Returns the rabbitmq connection url (e.g. amqp://user:password@host:port/vhost)
    #
    # @param protocol [String] the protocol to use in the string (default: "amqp://")
    # @param database [String] the database to use in the string (default: @database)
    # @param options [Hash] the options to use in the query string (default: {})
    # @return [String] the rabbitmq url
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def rabbitmq_url(protocol: "amqp://", username: nil, password: nil, vhost: nil)
      username ||= @username
      password ||= @password
      vhost ||= @vhost
      vhost = "/#{vhost}" unless vhost.start_with?("/")
      vhost = "" if vhost == "/"

      # amqp://user:pass@host:10000/vhost
      "#{protocol}#{username}:#{password}@#{host}:#{mapped_port(port)}#{vhost}"
    end

    alias_method :connection_url, :rabbitmq_url

    # Returns the rabbitmq management UI url (e.g. http://user:password@host:port)
    #
    # @param protocol [String] the protocol to use in the string (default: "http")
    # @return [String] the url for the management UI. Returns nil if the management UI is not available.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def management_ui_url(protocol: "http")
      port = mapped_port(management_ui_port)
      port.nil? ? nil : "#{protocol}://#{host}:#{port}"
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

    # Returns the container's first mapped port (the one used by the queue)
    #
    # @return [Integer] The container's first mapped port.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    def first_mapped_port
      raise ContainerNotStartedError unless @_container
      mapped_port(port)
    end

    private

    def _configure
      add_env("RABBITMQ_DEFAULT_USER", @username)
      add_env("RABBITMQ_DEFAULT_PASS", @password)
      add_env("RABBITMQ_DEFAULT_VHOST", @vhost) if @vhost
    end

    def _default_healthcheck_options
      {test: %w[rabbitmqctl node_health_check], interval: 10, timeout: 10, retries: 5}
    end
  end
end
