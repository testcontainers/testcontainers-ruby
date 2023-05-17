require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "rspec"
  gem "testcontainers-core", path: "../core"
  gem "dalli"
end

require "dalli"
require "rspec"
require "rspec/autorun"
require "testcontainers"

RSpec.configure do |config|
  config.add_setting :memcached_container, default: nil

  config.before(:suite) do
    container = Testcontainers::GenericContainer.new("memcached:latest").with_exposed_port(11211).start
    ENV["MEMCACHED_HOST"] = "#{container.host}:#{container.mapped_port(11211)}"
    config.memcached_container = container
  end

  config.after(:suite) do
    config.memcached_container&.stop if config.memcached_container&.running?
    config.memcached_container&.remove
  end
end

RSpec.describe "Memcached" do
  before(:all) do
    @memcached = Dalli::Client.new(ENV["MEMCACHED_HOST"])
  end

  before(:each) do
    @memcached.flush
  end

  it "set/get keys" do
    @memcached.set("foo", "bar")
    expect(@memcached.get("foo")).to eq("bar")
  end

  it "set/get multiple keys" do
    @memcached.set("foo", "bar")
    @memcached.set("baz", "qux")
    expect(@memcached.get_multi("foo", "baz")).to eq("foo" => "bar", "baz" => "qux")
  end
end
