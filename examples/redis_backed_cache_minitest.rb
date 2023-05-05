require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "redis", require: "redis"
  gem "minitest"
  gem "minitest-hooks"
  gem "testcontainers-core", path: "../core", require: "testcontainers"
end

class RedisBackedCache
  def initialize(host, port)
    @redis = Redis.new(host: host, port: port)
  end

  def put(key, value)
    @redis.set(key, value)
  end

  def get(key)
    @redis.get(key)
  end

  def clear
    @redis.flushall
  end
end

require "minitest/autorun"
require "minitest/hooks/test"

class RedisBackedCacheTest < Minitest::Test
  include Minitest::Hooks

  def before_all
    super

    @redis_container = Testcontainers::DockerContainer.new("redis:6.2-alpine").with_exposed_ports(6379)
    @redis_container.start
    @redis_container.wait_for_tcp_port(6379)
  end

  def after_all
    if @redis_container&.exists?
      @redis_container&.stop! if @redis_container&.running?
      @redis_container&.remove
    end

    super
  end

  def setup
    address = @redis_container.host
    port = @redis_container.mapped_port(6379)
    @cache = RedisBackedCache.new(address, port)
  end

  def teardown
    @cache&.clear
  end

  def test_put_and_get
    @cache.put("test", "example")
    retrieved = @cache.get("test")
    assert_equal "example", retrieved
  end

  # Add more tests here, and they will reuse the same container.
end
