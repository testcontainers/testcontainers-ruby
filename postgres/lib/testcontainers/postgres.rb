require_relative "postgres/version"
require "testcontainers"
require "uri"

module Testcontainers
  # PostgresContainer class is used to manage containers that runs a PostgresQL database
  #
  # @attr_reader [String] port used by the container
  # @attr_reader [String] username used by the container
  # @attr_reader [String] password used by the container
  # @attr_reader [String] database used by the container
  class PostgresContainer < ::Testcontainers::DockerContainer
    # Default port used by the container
    POSTGRES_DEFAULT_PORT = 5432

    # Default image used by the container
    POSTGRES_DEFAULT_IMAGE = "postgres:latest"

    POSTGRES_DEFAULT_USERNAME = "test"
    POSTGRES_DEFAULT_PASSWORD = "test"
    POSTGRES_DEFAULT_ROOT_USERNAME = "root"
    POSTGRES_DEFAULT_DATABASE = "test"

    attr_reader :port, :username, :password, :database

    # Initializes a new instance of PostgresContainer
    #
    # @param image [String] the image to use
    # @param username [String] the username to use
    # @param password [String] the password to use
    # @param database [String] the database to use
    # @param port [String] the port to use
    # @param kwargs [Hash] the options to pass to the container. See {DockerContainer#initialize}
    # @return [PostgresContainer] a new instance of PostgresContainer
    def initialize(image = POSTGRES_DEFAULT_IMAGE, username: nil, password: nil, database: nil, port: nil, **kwargs)
      super(image, **kwargs)
      @port = port || ENV.fetch("POSTGRES_PORT", POSTGRES_DEFAULT_PORT)
      @username = username || ENV.fetch("POSTGRES_USER", POSTGRES_DEFAULT_USERNAME)
      @password = password || ENV.fetch("POSTGRES_PASSWORD", POSTGRES_DEFAULT_PASSWORD)
      @database = database || ENV.fetch("POSTGRES_DATABASE", POSTGRES_DEFAULT_DATABASE)
    end

    # Starts the container
    #
    # @return [PostgresContainer] self
    def start
      with_exposed_ports(@port)
      _configure
      super
    end

    # Returns the host used to connect to the container
    # If the host is "localhost", it is replaced by "127.0.0.1" since Postgres fallbacks
    # to a socket connection with "localhost"
    #
    # @return [String] the host used to connect to the container
    def host
      host = super
      (host == "localhost") ? "127.0.0.1" : host
    end

    # Returns the database url (e.g. postgres://user:password@host:port/database)
    #
    # @param protocol [String] the protocol to use in the string (default: "postgres")
    # @param database [String] the database to use in the string (default: @database)
    # @param options [Hash] the options to use in the query string (default: {})
    # @return [String] the database url
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def database_url(protocol: "postgres", username: nil, password: nil, database: nil, options: {})
      database ||= @database
      username ||= @username
      password ||= @password
      query_string = options.empty? ? "" : "?#{URI.encode_www_form(options)}"

      "#{protocol}://#{username}:#{password}@#{host}:#{mapped_port(port)}/#{database}#{query_string}"
    end

    # Sets the database to use
    #
    # @param database [String] the database to use
    # @return [PostgresContainer] self
    def with_database(database)
      @database = database
      self
    end

    # Sets the username to use
    #
    # @param username [String] the username to use
    # @return [PostgresContainer] self
    def with_username(username)
      @username = username
      self
    end

    # Sets the password to use
    #
    # @param password [String] the password to use
    # @return [PostgresContainer] self
    def with_password(password)
      @password = password
      self
    end

    private

    def _configure
      add_env("POSTGRES_DATABASE", @database)
      add_env("POSTGRES_USER", @username) if @username != POSTGRES_DEFAULT_ROOT_USERNAME

      if !@password.nil? && !@password.empty?
        add_env("POSTGRES_PASSWORD", @password)
        add_env("POSTGRES_ROOT_PASSWORD", @password)
      elsif @username == POSTGRES_DEFAULT_ROOT_USERNAME
        add_env("POSTGRES_ALLOW_EMPTY_PASSWORD", "yes")
      else
        raise ContainerLaunchException, "Password is required for non-root users"
      end
    end
  end
end
