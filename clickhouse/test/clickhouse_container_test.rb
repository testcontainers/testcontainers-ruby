# frozen_string_literal: true

require "net/http"
require "test_helper"

class ClickhouseContainerTest < TestcontainersTest
  def before_all
    super

    @container = Testcontainers::ClickhouseContainer.new
    @container.start
    @host = @container.host
    @database = @container.database
    @port = @container.mapped_port(@container.port)
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
    assert_equal "clickhouse/clickhouse-server:latest", @container.image
  end

  def test_it_supports_custom_image
    container = Testcontainers::ClickhouseContainer.new("clickhouse/clickhouse-server:26.1")
    assert_equal "clickhouse/clickhouse-server:26.1", container.image
  end

  def test_it_returns_the_default_http_port
    assert_equal 8123, @container.http_port
  end

  def test_it_returns_the_default_port
    assert_equal 9000, @container.port
  end

  def test_it_returns_the_default_tcp_port
    assert_equal 9000, @container.tcp_port
  end

  def test_it_has_the_default_ports_mapped
    assert @container.mapped_port(8123)
    assert @container.mapped_port(9000)
  end

  def test_it_returns_the_default_clickhouse_url
    assert_equal "clickhouse://default:password@#{@host}:#{@port}/default", @container.clickhouse_url
  end

  def test_it_returns_the_default_clickhouse_http_url
    assert_equal "http://default:password@#{@host}:#{@http_port}", @container.clickhouse_http_url
  end

  def test_it_returns_the_clickhouse_http_url_with_custom_protocol
    assert_equal "https://default:password@#{@host}:#{@http_port}", @container.clickhouse_http_url(protocol: "https")
  end

  def test_it_returns_the_clickhouse_url_with_custom_username_and_password
    assert_equal "clickhouse://foo:bar@#{@host}:#{@port}/#{@database}", @container.clickhouse_url(username: "foo", password: "bar")
  end

  def test_it_is_reachable
    uri = URI("#{@container.clickhouse_http_url}/?query=SELECT+1")
    uri.user = nil
    uri.password = nil
    response = Net::HTTP.start(uri.host, uri.port) do |http|
      req = Net::HTTP::Get.new(uri)
      req.basic_auth(@container.username, @container.password)
      http.request(req)
    end
    assert_equal "200", response.code
    assert_equal "1\n", response.body
  end
end
