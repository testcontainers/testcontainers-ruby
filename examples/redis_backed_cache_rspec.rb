require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "redis", require: "redis"
  gem "rspec", require: "rspec"
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

require "rspec/autorun"

RSpec.configure do |config|
  config.before(:suite) do
    $redis_container = Testcontainers::DockerContainer.new("redis:6.2-alpine").with_exposed_ports(6379).start
    $redis_container.wait_for_tcp_port(6379) # wait for Redis to start
  end

  config.after(:suite) do
    $redis_container&.stop if $redis_container&.running?
    $redis_container&.remove
  end
end

RSpec.describe RedisBackedCache do
  let(:cache) { RedisBackedCache.new($redis_container.host, $redis_container.mapped_port(6379)) }

  before { cache.clear }

  it "can put and get values" do
    cache.put("foo", "bar")
    expect(cache.get("foo")).to eq("bar")
  end
end
