# frozen_string_literal: true

require "test_helper"

class NginxContainerTest < TestcontainersTest
  def before_all
    super

    @container = Testcontainers::NginxContainer.new
    @container.start
    @host = @container.host
    @port = @container.first_mapped_port
  end

  def after_all
    if @container&.exists?
      @container&.stop if @container&.running?
      @container&.remove
    end

    super
  end

  def test_it_returns_the_default_image
    assert_equal "nginx:latest", @container.image
  end

  def test_it_supports_custom_image
    container = Testcontainers::NginxContainer.new("nginx:1.18-alpine")
    assert_equal "nginx:1.18-alpine", container.image
  end

  def test_it_returns_the_default_port
    assert_equal 80, @container.port
  end

  def test_it_has_the_default_port_mapped
    assert @container.mapped_port(80)
  end

  def test_it_supports_custom_port
    container = Testcontainers::NginxContainer.new(port: 8080)
    assert_equal 8080, container.port
  end

  def test_it_supports_custom_keyword_arguments
    container = Testcontainers::NginxContainer.new(filesystem_binds: ["#{Dir.pwd}/custom/conf:/etc/nginx/conf.d:rw"])
    assert_equal ["#{Dir.pwd}/custom/conf:/etc/nginx/conf.d:rw"], container.filesystem_binds
  end

  def test_it_returns_the_default_server_url
    assert_equal "http://#{@host}:#{@port}", @container.server_url
  end

  def test_it_returns_the_server_url_with_custom_protocol
    assert_equal "https://#{@host}:#{@port}", @container.server_url(protocol: "https")
  end

  def test_it_is_reachable
    @container.wait_for_logs(/start worker process/)

    uri = URI.parse(@container.server_url)
    response = Net::HTTP.get_response(uri)

    assert_equal "200", response.code
  end
end
