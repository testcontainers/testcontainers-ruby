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
  config.add_setting :redis, default: nil

  config.before(:suite) do
    config.redis = Testcontainers::DockerContainer.new("redis:6.2-alpine").with_exposed_ports("6379")
    config.redis.start
    config.redis.wait_for_tcp_port("6379") # wait for Redis to start
    config.redis.wait_for_logs(/Ready to accept connections/)
  end

  config.after(:suite) do
    config.redis&.stop if config.redis&.running?
    config.redis&.remove
  end
end

RSpec.describe RedisBackedCache do
  let(:cache) { RedisBackedCache.new(RSpec.configuration.redis.host, RSpec.configuration.redis.mapped_port(6379)) }

  before { cache.clear }

  it "can put and get values" do
    cache.put("foo", "bar")
    expect(cache.get("foo")).to eq("bar")
  end
end
