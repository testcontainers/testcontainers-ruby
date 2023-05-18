# frozen_string_literal: true

require "test_helper"
require "elasticsearch"

class ElasticsearchContainerTest < TestcontainersTest
  def before_all
    super

    @container = Testcontainers::ElasticsearchContainer.new
    @container.start
    @host = @container.host
    @http_port = @container.mapped_port(@container.http_port)
  end

  def after_all
    if @container&.exists?
      @container&.stop if @container&.running?
      @container&.remove
    end

    super
  end

  def test_it_returns_the_default_image
    assert_equal "docker.elastic.co/elasticsearch/elasticsearch:8.7.1", @container.image
  end

  def test_it_supports_custom_image
    container = Testcontainers::ElasticsearchContainer.new("docker.elastic.co/elasticsearch/elasticsearch:7.17.10")
    assert_equal "docker.elastic.co/elasticsearch/elasticsearch:7.17.10", container.image
  end

  def test_it_returns_the_default_http_port
    assert_equal 9200, @container.http_port
  end

  def test_it_returns_the_default_tcp_port
    assert_equal 9300, @container.tcp_port
  end

  def test_it_has_the_default_ports_mapped
    assert @container.mapped_port(9200)
    assert @container.mapped_port(9300)
  end

  def test_it_returns_the_default_elasticsearch_url
    assert_equal "http://elastic:elastic@#{@host}:#{@http_port}", @container.elasticsearch_url
  end

  def test_it_returns_the_elasticsearch_url_with_custom_protocol
    assert_equal "https://elastic:elastic@#{@host}:#{@http_port}", @container.elasticsearch_url(protocol: "https")
  end

  def test_it_returns_the_elasticsearch_url_with_custom_username_and_password
    assert_equal "http://foo:bar@#{@host}:#{@http_port}", @container.elasticsearch_url(username: "foo", password: "bar")
  end

  def test_it_is_reachable
    client = Elasticsearch::Client.new(url: @container.elasticsearch_url)
    assert client.ping
  end
end
