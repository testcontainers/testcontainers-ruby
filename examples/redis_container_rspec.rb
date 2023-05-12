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
  config.before(:suite) do
    config.add_setting :redis_container, default: nil
    config.redis_container = Testcontainers::RedisContainer.new.start
    ENV["DATABASE_URL"] = config.redis_container.redis_url
  end

  config.after(:suite) do
    config.redis_container&.stop if config.redis_container&.running?
    config.redis_container&.remove
  end
end

RSpec.describe "Redis" do
  before(:all) do
    @redis = Redis.new(url: ENV["DATABASE_URL"])
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
