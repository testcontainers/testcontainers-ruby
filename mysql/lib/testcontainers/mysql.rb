require_relative "mysql/version"
require "testcontainers"
require "uri"

module Testcontainers
  # MysqlContainer class is used to manage containers that runs a MySQL database
  #
  # @attr_reader [String] port used by the container
  # @attr_reader [String] username used by the container
  # @attr_reader [String] password used by the container
  # @attr_reader [String] database used by the container
  class MysqlContainer < ::Testcontainers::DockerContainer
    # Default port used by the container
    MYSQL_DEFAULT_PORT = 3306

    # Default image used by the container
    MYSQL_DEFAULT_IMAGE = "mysql:latest"

    MYSQL_DEFAULT_USERNAME = "test"
    MYSQL_DEFAULT_PASSWORD = "test"
    MYSQL_DEFAULT_ROOT_USERNAME = "root"
    MYSQL_DEFAULT_DATABASE = "test"

    attr_reader :port, :username, :password, :database

    # Initializes a new instance of MysqlContainer
    #
    # @param image [String] the image to use
    # @param username [String] the username to use
    # @param password [String] the password to use
    # @param database [String] the database to use
    # @param port [String] the port to use
    # @param kwargs [Hash] the options to pass to the container. See {DockerContainer#initialize}
    # @return [MysqlContainer] a new instance of MysqlContainer
    def initialize(image = MYSQL_DEFAULT_IMAGE, username: nil, password: nil, database: nil, port: nil, **kwargs)
      super(image, **kwargs)
      @port = port || ENV.fetch("MYSQL_PORT", MYSQL_DEFAULT_PORT)
      @username = username || ENV.fetch("MYSQL_USER", MYSQL_DEFAULT_USERNAME)
      @password = password || ENV.fetch("MYSQL_PASSWORD", MYSQL_DEFAULT_PASSWORD)
      @database = database || ENV.fetch("MYSQL_DATABASE", MYSQL_DEFAULT_DATABASE)
    end

    # Starts the container
    #
    # @return [MysqlContainer] self
    def start
      with_exposed_ports(@port)
      _configure
      super
    end

    # Returns the host used to connect to the container
    # If the host is "localhost", it is replaced by "127.0.0.1" since MySQL fallbacks
    # to a socket connection with "localhost"
    #
    # @return [String] the host used to connect to the container
    def host
      host = super
      (host == "localhost") ? "127.0.0.1" : host
    end

    # Returns the database url (e.g. mysql://user:password@host:port/database)
    #
    # @param protocol [String] the protocol to use in the string (default: "mysql")
    # @param database [String] the database to use in the string (default: @database)
    # @param options [Hash] the options to use in the query string (default: {})
    # @return [String] the database url
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def database_url(protocol: "mysql", username: nil, password: nil, database: nil, options: {})
      database ||= @database
      username ||= @username
      password ||= @password
      query_string = options.empty? ? "" : "?#{URI.encode_www_form(options)}"

      "#{protocol}://#{username}:#{password}@#{host}:#{mapped_port(port)}/#{database}#{query_string}"
    end

    # Sets the database to use
    #
    # @param database [String] the database to use
    # @return [MysqlContainer] self
    def with_database(database)
      @database = database
      self
    end

    # Sets the username to use
    #
    # @param username [String] the username to use
    # @return [MysqlContainer] self
    def with_username(username)
      @username = username
      self
    end

    # Sets the password to use
    #
    # @param password [String] the password to use
    # @return [MysqlContainer] self
    def with_password(password)
      @password = password
      self
    end

    private

    def _configure
      add_env("MYSQL_DATABASE", @database)
      add_env("MYSQL_USER", @username) if @username != MYSQL_DEFAULT_ROOT_USERNAME

      if !@password.nil? && !@password.empty?
        add_env("MYSQL_PASSWORD", @password)
        add_env("MYSQL_ROOT_PASSWORD", @password)
      elsif @username == MYSQL_DEFAULT_ROOT_USERNAME
        add_env("MYSQL_ALLOW_EMPTY_PASSWORD", "yes")
      else
        raise ContainerLaunchException, "Password is required for non-root users"
      end
    end
  end
end
