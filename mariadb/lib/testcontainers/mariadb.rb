require_relative "mariadb/version"
require "testcontainers"

module Testcontainers
  # MariadbContainer class is used to manage containers that runs a MariaDB database
  #
  # @attr_reader [String] username used by the container
  # @attr_reader [String] password used by the container
  # @attr_reader [String] database used by the container
  class MariadbContainer < ::Testcontainers::DockerContainer
    # Default port used by the container
    MARIADB_DEFAULT_PORT = 3306

    # Default image used by the container
    MARIADB_DEFAULT_IMAGE = "mariadb:latest"

    MARIADB_DEFAULT_USERNAME = "test"
    MARIADB_DEFAULT_PASSWORD = "test"
    MARIADB_DEFAULT_ROOT_USERNAME = "root"
    MARIADB_DEFAULT_DATABASE = "test"

    attr_reader :username, :password, :database

    # Initializes a new instance of MariadbContainer
    #
    # @param image [String] the image to use
    # @param username [String] the username to use
    # @param password [String] the password to use
    # @param database [String] the database to use
    # @param port [String] the port to use
    # @param kwargs [Hash] the options to pass to the container. See {DockerContainer#initialize}
    # @return [MariadbContainer] a new instance of MariadbContainer
    def initialize(image = MARIADB_DEFAULT_IMAGE, username: nil, password: nil, database: nil, port: nil, **kwargs)
      super(image, **kwargs)
      @username = username || ENV.fetch("MARIADB_USER", MARIADB_DEFAULT_USERNAME)
      @password = password || ENV.fetch("MARIADB_PASSWORD", MARIADB_DEFAULT_PASSWORD)
      @database = database || ENV.fetch("MARIADB_DATABASE", MARIADB_DEFAULT_DATABASE)
      @healthcheck ||= add_healthcheck(_default_healthcheck_options)
      add_wait_for(:healthcheck) unless wait_for_user_defined?
    end

    # Starts the container
    #
    # @return [MariadbContainer] self
    def start
      with_exposed_ports(port)
      _configure
      super
    end

    # Returns the host used to connect to the container
    # If the host is "localhost", it is replaced by "127.0.0.1" since MariaDB fallbacks
    # to a socket connection with "localhost"
    #
    # @return [String] the host used to connect to the container
    def host
      host = super
      (host == "localhost") ? "127.0.0.1" : host
    end

    # Returns the port used by the container
    #
    # @return [Integer] the port used by the container
    def port
      MARIADB_DEFAULT_PORT
    end

    # Returns the database url (e.g. mariadb://user:password@host:port/database)
    #
    # @param protocol [String] the protocol to use in the string (default: "mariadb")
    # @param database [String] the database to use in the string (default: @database)
    # @param options [Hash] the options to use in the query string (default: {})
    # @return [String] the database url
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def database_url(protocol: "mariadb", username: nil, password: nil, database: nil, options: {})
      database ||= @database
      username ||= @username
      password ||= @password
      query_string = options.empty? ? "" : "?#{URI.encode_www_form(options)}"

      "#{protocol}://#{username}:#{password}@#{host}:#{mapped_port(port)}/#{database}#{query_string}"
    end

    # Sets the database to use
    #
    # @param database [String] the database to use
    # @return [MariadbContainer] self
    def with_database(database)
      @database = database
      self
    end

    # Sets the username to use
    #
    # @param username [String] the username to use
    # @return [MariadbContainer] self
    def with_username(username)
      @username = username
      self
    end

    # Sets the password to use
    #
    # @param password [String] the password to use
    # @return [MariadbContainer] self
    def with_password(password)
      @password = password
      self
    end

    private

    def _configure
      add_env("MARIADB_DATABASE", @database)
      add_env("MARIADB_USER", @username) if @username != MARIADB_DEFAULT_ROOT_USERNAME

      if !@password.nil? && !@password.empty?
        add_env("MARIADB_PASSWORD", @password)
        add_env("MARIADB_ROOT_PASSWORD", @password)
      elsif @username == MARIADB_DEFAULT_ROOT_USERNAME
        add_env("MARIADB_ALLOW_EMPTY_PASSWORD", "yes")
      else
        raise ContainerLaunchException, "Password is required for non-root users"
      end
    end

    def _default_healthcheck_options
      {test: ["/usr/local/bin/healthcheck.sh", "--connect"], interval: 1, timeout: 5, retries: 5}
    end
  end
end
