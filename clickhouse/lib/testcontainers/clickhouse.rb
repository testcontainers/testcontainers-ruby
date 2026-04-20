# frozen_string_literal: true

require_relative "clickhouse/version"
require "testcontainers"

module Testcontainers
  # ClickhouseContainer class is used to manage containers that runs a Clickhouse server
  #
  # @attr_reader [String] username used by the container
  # @attr_reader [String] password used by the container
  # @attr_reader [String] database used by the container
  class ClickhouseContainer < ::Testcontainers::DockerContainer
    # Default ports used by the container
    CLICKHOUSE_DEFAULT_PORT = 9000
    CLICKHOUSE_DEFAULT_HTTP_PORT = 8123

    # Default image used by the container
    CLICKHOUSE_DEFAULT_IMAGE = "clickhouse/clickhouse-server:latest"

    # Default credentials used by the container
    CLICKHOUSE_DEFAULT_USER = "default"
    CLICKHOUSE_DEFAULT_PASS = "password"
    CLICKHOUSE_DB = "default"

    attr_reader :username, :password, :database

    # Default "wait for" strategy
    WAIT_FOR_PROC = ->(container) {
      container.wait_for_http(container_port: 8123, timeout: 30, interval: 1.0, path: "/", status: 200)
    }

    # Initializes a new instance of ClickhouseContainer
    #
    #  @param image [String] the image to use
    #  @param username [String] the username to use
    #  @param password [String] the password to use
    #  @param database [String]
    #  @param kwargs [Hash] the options to pass to the container. See {DockerContainer#initialize}
    #  @return [ClickhouseContainer] a new instance of ClickhouseContainer
    def initialize(image = CLICKHOUSE_DEFAULT_IMAGE, username: nil, password: nil, database: nil, **kwargs)
      super(image, wait_for: WAIT_FOR_PROC, exposed_ports: [CLICKHOUSE_DEFAULT_PORT, CLICKHOUSE_DEFAULT_HTTP_PORT], **kwargs)
      @username = username || ENV.fetch("CLICKHOUSE_USER", CLICKHOUSE_DEFAULT_USER)
      @password = password || ENV.fetch("CLICKHOUSE_PASSWORD", CLICKHOUSE_DEFAULT_PASS)
      @database = database || ENV.fetch("CLICKHOUSE_DB", CLICKHOUSE_DB)
    end

    # Starts the container
    #
    # @return [ClickhouseContainer] self
    def start
      _configure
      super
    end

    # Returns the native TCP port used to connect to the container
    #
    # @return [Integer] the port used by the container
    def port
      CLICKHOUSE_DEFAULT_PORT
    end
    alias_method :tcp_port, :port

    # Returns the HTTP port used to connect to the container via HTTP/HTTPS
    #
    # @return [Integer] the HTTP/HTTPS port used by the container
    def http_port
      CLICKHOUSE_DEFAULT_HTTP_PORT
    end

    # Returns the clickhouse connection url (e.g. clickhouse://user:password@host:port/database)
    #
    # @param protocol [String] the protocol to use in the string (default: "clickhouse://")
    # @param username [String] the username to use in the string (default: @username)
    # @param password [String] the password to use in the string (default: @password)
    # @param database [String] the database to use in the string (default: @database)
    # @return [String] the clickhouse url
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def clickhouse_url(protocol: "clickhouse://", username: nil, password: nil, database: nil)
      username ||= @username
      password ||= @password
      database ||= @database
      database = "/#{database}" unless database.start_with?("/")

      # clickhouse://user:pass@host:9000/database
      "#{protocol}#{username}:#{password}@#{host}:#{mapped_port(port)}#{database}"
    end

    alias_method :connection_url, :clickhouse_url

    # Returns the clickhouse connection url (e.g. http://user:password@host:port)
    #
    # @param protocol [String] the protocol to use in the string (default: "http")
    # @return [String] the url for the management UI. Returns nil if the management UI is not available.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def clickhouse_http_url(protocol: "http")
      port = mapped_port(http_port)
      port.nil? ? nil : "#{protocol}://#{username}:#{password}@#{host}:#{port}"
    end

    # Sets the database to use
    #
    # @param database [String] the database to use
    # @return [ClickhouseContainer] self
    def with_database(database)
      @database = database
      self
    end

    # Sets the username to use
    #
    # @param username [String] the username to use
    # @return [ClickhouseContainer] self
    def with_username(username)
      @username = username
      self
    end

    # Sets the password to use
    #
    # @param password [String] the password to use
    # @return [ClickhouseContainer] self
    def with_password(password)
      @password = password
      self
    end

    # Returns the mapped TCP port
    #
    # @return [Integer] The container's mapped TCP port.
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    def first_mapped_port
      raise ContainerNotStartedError unless @_container
      mapped_port(port)
    end

    private

    def _configure
      add_env("CLICKHOUSE_USER", @username)
      add_env("CLICKHOUSE_PASSWORD", @password)
      add_env("CLICKHOUSE_DB", @database)
    end
  end
end
