require_relative "opensearch/version"
require "testcontainers"

module Testcontainers
  # OpensearchContainer manages Docker containers running OpenSearch.
  # It mirrors the Elasticsearch container API but targets the OpenSearch images
  # and defaults, including disabled security for simple integration tests.
  class OpensearchContainer < ::Testcontainers::DockerContainer
    OPENSEARCH_DEFAULT_HTTP_PORT = 9200
    OPENSEARCH_DEFAULT_METRICS_PORT = 9600
    OPENSEARCH_DEFAULT_IMAGE = "opensearchproject/opensearch:2.12.0"

    # Initializes a new OpenSearch container.
    #
    # @param image [String] Docker image to use.
    # @param http_port [Integer] Port to expose for HTTP traffic (default: 9200).
    # @param metrics_port [Integer] Port to expose for the metrics endpoint (default: 9600).
    # @param kwargs [Hash] Additional options forwarded to DockerContainer.
    attr_reader :http_port, :metrics_port

    def initialize(image = OPENSEARCH_DEFAULT_IMAGE, http_port: nil, metrics_port: nil, **kwargs)
      @http_port = http_port || OPENSEARCH_DEFAULT_HTTP_PORT
      @metrics_port = metrics_port || OPENSEARCH_DEFAULT_METRICS_PORT
      super(image, **kwargs)
    end

    # Starts the container with the appropriate exposed ports and environment.
    def start
      with_exposed_ports(http_port, metrics_port)
      _configure
      super
    end

    # Returns the URL to access the OpenSearch HTTP endpoint.
    #
    # @param protocol [String] scheme to use (default: "http").
    # @param port [Integer] HTTP port to use (default: mapped http_port).
    def opensearch_url(protocol: "http", port: http_port)
      "#{protocol}://#{host}:#{mapped_port(port)}"
    end

    private

    def _configure
      add_env("discovery.type", "single-node") unless get_env("discovery.type")
      add_env("bootstrap.memory_lock", "true") unless get_env("bootstrap.memory_lock")
      add_env("plugins.security.disabled", "true") unless get_env("plugins.security.disabled")
      add_env("DISABLE_INSTALL_DEMO_CONFIG", "true") unless get_env("DISABLE_INSTALL_DEMO_CONFIG")
      add_env("DISABLE_SECURITY_PLUGIN", "true") unless get_env("DISABLE_SECURITY_PLUGIN")
      add_env("OPENSEARCH_JAVA_OPTS", "-Xms512m -Xmx512m") unless get_env("OPENSEARCH_JAVA_OPTS")
    end
  end
end
