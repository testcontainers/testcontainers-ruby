require_relative "elasticsearch/version"
require "testcontainers"

module Testcontainers
  # ElasticsearchContainer class is used to manage Docker containers running Elasticsearch.
  # It extends the generic DockerContainer class and provides Elasticsearch-specific functionality.
  #
  # @attr_reader http_port [Integer] the port exposed for HTTP traffic
  # @attr_reader tcp_port [Integer] the port exposed for TCP traffic
  # @attr_reader username [String] the Elasticsearch username
  # @attr_reader password [String] the Elasticsearch password
  class ElasticsearchContainer < ::Testcontainers::DockerContainer
    ELASTICSEARCH_DEFAULT_HTTP_PORT = 9200
    ELASTICSEARCH_DEFAULT_TCP_PORT = 9300
    ELASTICSEARCH_DEFAULT_IMAGE = "docker.elastic.co/elasticsearch/elasticsearch:8.7.1"
    ELASTICSEARCH_DEFAULT_USERNAME = "elastic"
    ELASTICSEARCH_DEFAULT_PASSWORD = "elastic"

    attr_reader :http_port, :tcp_port, :username, :password

    # Initializes a new ElasticsearchContainer instance.
    #
    # @param image [String] the Elasticsearch Docker image to use
    # @param http_port [Integer] the port to expose for HTTP traffic, defaults to 9200
    # @param tcp_port [Integer] the port to expose for TCP traffic, defaults to 9300
    # @param username [String] the Elasticsearch username, defaults to 'elastic'
    # @param password [String] the Elasticsearch password, defaults to 'elastic'
    # @param kwargs [Hash] the options to pass to the container. See {DockerContainer#initialize}
    # @return [ElasticsearchContainer] a new ElasticsearchContainer instance
    def initialize(image = ELASTICSEARCH_DEFAULT_IMAGE, http_port: nil, tcp_port: nil, username: nil, password: nil, **kwargs)
      super(image, **kwargs)
      @http_port = http_port || ELASTICSEARCH_DEFAULT_HTTP_PORT
      @tcp_port = tcp_port || ELASTICSEARCH_DEFAULT_TCP_PORT
      @username = username || ELASTICSEARCH_DEFAULT_USERNAME
      @password = password || ELASTICSEARCH_DEFAULT_PASSWORD
      @healthcheck ||= add_healthcheck(_default_healthcheck_options)
      @wait_for ||= add_wait_for(:healthcheck)
    end

    # Starts the container
    #
    # @return [ElasticsearchContainer] self
    def start
      with_exposed_ports(@http_port, @tcp_port)
      _configure
      super
    end

    # Returns the URL to access Elasticsearch
    #
    # @param protocol [String] the protocol (http or https), defaults to 'http'
    # @param port [Integer] the port to use, defaults to the HTTP port
    # @param username [String] the username to use, defaults to the container username
    # @param password [String] the password to use, defaults to the container password
    # @return [String] the URL to access Elasticsearch
    def elasticsearch_url(protocol: nil, port: nil, username: nil, password: nil)
      if protocol.nil?
        protocol = (get_env("xpack.security.enabled") == "true") ? "https" : "http"
      end
      username ||= @username
      password ||= @password
      port ||= @http_port

      "#{protocol}://#{username}:#{password}@#{host}:#{mapped_port(port)}"
    end

    private

    def _configure
      add_env("ELASTIC_PASSWORD", @password.to_s)
      add_env("discovery.type", "single-node") unless get_env("discovery.type")
      add_env("xpack.security.enabled", "false") unless get_env("xpack.security.enabled")
    end

    def _default_healthcheck_options
      {test: ["curl", "--silent", "--fail", "localhost:#{@http_port}/_cluster/health"], interval: 1, timeout: 5, retries: 5}
    end
  end
end
