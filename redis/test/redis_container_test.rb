# frozen_string_literal: true

require "test_helper"

class RedisContainerTest < TestcontainersTest
  def before_all
    super

    @container = Testcontainers::RedisContainer.new
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
    assert_equal "redis:latest", @container.image
  end

  def test_it_supports_custom_image
    container = Testcontainers::RedisContainer.new("redis:alpine")
    assert_equal "redis:alpine", container.image
  end

  def test_it_returns_the_default_port
    assert_equal 6379, @container.port
  end

  def test_it_has_the_default_port_mapped
    assert @container.mapped_port(6379)
  end

  def test_it_supports_custom_port
    container = Testcontainers::RedisContainer.new(port: 16379)
    assert_equal 16379, container.port
  end

  def test_it_supports_custom_keyword_arguments
    container = Testcontainers::RedisContainer.new(filesystem_binds: ["#{Dir.pwd}/custom/conf:/usr/local/etc/redis/redis.conf:rw"])
    assert_equal ["#{Dir.pwd}/custom/conf:/usr/local/etc/redis/redis.conf:rw"], container.filesystem_binds
  end

  def test_it_returns_the_default_redis_url
    assert_equal "redis://#{@host}:#{@port}/0", @container.redis_url
  end

  def test_it_returns_the_redis_url_with_custom_protocol
    assert_equal "rediss://#{@host}:#{@port}/0", @container.redis_url(protocol: "rediss")
  end

  def test_it_returns_the_redis_url_with_custom_db_number
    assert_equal "redis://#{@host}:#{@port}/3", @container.redis_url(db: 3)
  end

  def test_it_is_reachable
    client = Redis.new(host: @host, port: @port, db: 0)
    assert_equal "PONG", client.ping
  end
end
