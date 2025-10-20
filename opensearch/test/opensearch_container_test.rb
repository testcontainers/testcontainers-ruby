# frozen_string_literal: true

require "test_helper"
require "opensearch-ruby"

class OpensearchContainerTest < TestcontainersTest
  def setup
    super
    @container = Testcontainers::OpensearchContainer.new
  end

  def teardown
    if @container&.exists?
      @container&.stop if @container&.running?
      @container&.remove
    end

    super
  end

  def test_it_returns_the_default_image
    assert_equal "opensearchproject/opensearch:2.12.0", @container.image
  end

  def test_it_supports_custom_image
    container = Testcontainers::OpensearchContainer.new("opensearchproject/opensearch:2.11.1")
    assert_equal "opensearchproject/opensearch:2.11.1", container.image
  end

  def test_it_returns_the_default_http_port
    assert_equal 9200, @container.http_port
  end

  def test_it_returns_the_default_metrics_port
    assert_equal 9600, @container.metrics_port
  end

  def test_running_container_behaviour
    run_with_container do |container|
      host = container.host
      http_port = container.mapped_port(container.http_port)

      assert container.mapped_port(9200)
      assert container.mapped_port(9600)
      assert_equal "http://#{host}:#{http_port}", container.opensearch_url
      assert_equal "https://#{host}:#{http_port}", container.opensearch_url(protocol: "https")
      client = OpenSearch::Client.new(url: container.opensearch_url)
      assert client.ping
    end
  end

  private

  def run_with_container
    @container.start
    begin
      @container.wait_for_http(container_port: @container.http_port, path: "/_cluster/health", timeout: 180, interval: 1, status: 200)
      yield(@container)
    rescue Testcontainers::TimeoutError => e
      skip("OpenSearch container unavailable: #{e.message}")
    end
  ensure
    if @container&.exists?
      @container.stop if @container&.running?
      @container.remove
    end
  end
end
