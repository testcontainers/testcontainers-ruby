require_relative "mongo/version"
require "testcontainers"

module Testcontainers
  # MongoContainer class is used to manage containers that runs a Mongo databese
  #
  # @attr_reader [String] username used by the container
  # @attr_reader [String] password used by the container
  # @attr_reader [String] database used by the container
  class MongoContainer < ::Testcontainers::DockerContainer
    # Default port used by the container
    MONGO_DEFAULT_PORT = 27017

    # Default image used by the container
    MONGO_DEFAULT_IMAGE = "mongo:latest"

    MONGO_DEFAULT_USERNAME = "test"
    MONGO_DEFAULT_PASSWORD = "test"
    MONGO_DEFAULT_DATABASE = "test"

    attr_reader :username, :password, :database

    # Initializes a new instance of MongoContainer
    #
    # @param image [String] the image to use
    # @param username [String] the username to use
    # @param password [String] the password to use
    # @param database [String] the database to use
    # @param port [String] the port to use
    # @param kwargs [Hash] the options to pass to the container. See {DockerContainer#initialize}
    # @return [MongoContainer] a new instance of MongoContainer
    def initialize(image = MONGO_DEFAULT_IMAGE, username: nil, password: nil, database: nil, **kwargs)
      super(image, **kwargs)
      @username = username || ENV.fetch("MONGO_USERNAME", MONGO_DEFAULT_USERNAME)
      @password = password || ENV.fetch("MONGO_PASSWORD", MONGO_DEFAULT_PASSWORD)
      @database = database || ENV.fetch("MONGO_DATABASE", MONGO_DEFAULT_DATABASE)
      @healthcheck ||= add_healthcheck(_default_healthcheck_options)
      add_wait_for(:healthcheck) unless wait_for_user_defined?
    end

    # Starts the container
    #
    # @return [MongoContainer] self
    def start
      with_exposed_ports(port)
      _configure
      super
    end

    # Returns the port used by the container
    #
    # @return [Integer] the port used by the container
    def port
      MONGO_DEFAULT_PORT
    end

    # Returns the database url (e.g. mongodb://user:password@host:port/database)
    #
    # @param protocol [String] the protocol to use in the string (default: "mongodb")
    # @param database [String] the database to use in the string (default: @database)
    # @param options [Hash] the options to use in the query string (default: {})
    # @return [String] the database url
    # @raise [ConnectionError] If the connection to the Docker daemon fails.
    # @raise [ContainerNotStartedError] If the container has not been started.
    def mongo_url(protocol: "mongodb", username: nil, password: nil, database: nil, options: {})
      database ||= @database
      username ||= @username
      password ||= @password
      query_string = options.empty? ? "" : "?#{URI.encode_www_form(options)}"

      "#{protocol}://#{username}:#{password}@#{host}:#{mapped_port(port)}/#{database}#{query_string}"
    end

    alias_method :database_url, :mongo_url

    # Sets the database to use
    #
    # @param database [String] the database to use
    # @return [MongoContainer] self
    def with_database(database)
      @database = database
      self
    end

    # Sets the username to use
    #
    # @param username [String] the password to use
    # @return [MongoContainer] self
    def with_username(username)
      @password = password
      self
    end

    # Sets the password to use
    #
    # @param password [String] the password to use
    # @return [MongoContainer] self
    def with_password(password)
      @password = password
      self
    end

    private

    def _configure
      add_env("MONGO_INITDB_DATABASE", @database)
      add_env("MONGO_INITDB_ROOT_USERNAME", @username)
      add_env("MONGO_INITDB_ROOT_PASSWORD", @password)
    end

    def _default_healthcheck_options
      {test: ["mongosh", "--eval", "db.adminCommand('ping')"], interval: 5, timeout: 5, retries: 3}
    end
  end
end
