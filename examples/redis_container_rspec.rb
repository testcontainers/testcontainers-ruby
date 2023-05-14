require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "rspec"
  gem "testcontainers-core", path: "../core"
  gem "testcontainers-redis", path: "../redis"
  gem "redis"
end

require "redis"
require "rspec"
require "rspec/autorun"
require "testcontainers/redis"

RSpec.configure do |config|
  config.add_setting :redis_container, default: nil
  config.add_setting :redis_url, default: nil

  config.before(:suite) do
    config.redis_container = Testcontainers::RedisContainer.new.start
    config.redis_url = config.redis_container.redis_url # We use this variable to avoid clashes with other Redis instances runnning on the host
  end

  config.after(:suite) do
    config.redis_container&.stop if config.redis_container&.running?
    config.redis_container&.remove
  end
end

RSpec.describe "Redis" do
  before(:all) do
    @redis = Redis.new(url: RSpec.configuration.redis_url)
  end

  before(:each) do
    @redis.flushdb
  end

  it "set/get keys" do
    @redis.set("foo", "bar")
    expect(@redis.get("foo")).to eq("bar")
  end

  it "set/get multiple keys" do
    @redis.mset("foo", "bar", "baz", "qux")
    expect(@redis.mget("foo", "baz")).to eq(["bar", "qux"])
  end
end
