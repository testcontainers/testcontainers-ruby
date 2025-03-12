# Quickstart Guide

This guide will help you get started with Testcontainers in Ruby by walking you through a simple example that demonstrates how to use the library.

Let's imagine we have a simple program that has a dependency on Redis, and we want to add some tests for it. In our imaginary program, there is a `RedisBackedCache` class that stores data in Redis.

## Step 1: Add Testcontainers as a dependency

First, add Testcontainers to your project by adding it to your Gemfile:

```ruby

gem "testcontainers"
```

And then run `bundle install`.


## Step 2: Start a Redis container for your tests

In your test class, e.g., `redis_backed_cache_test.rb`, require the necessary libraries and create a new instance of the `DockerContainer` class, specifying the Redis image and exposed ports:

```ruby
require "testcontainers"
require_relative "redis_backed_cache"
require "minitest/autorun"

class RedisBackedCacheTest < Minitest::Test
  def setup
    @redis_container = Testcontainers::DockerContainer.new("redis:6.2-alpine").with_exposed_ports(6379)
    @redis_container.start
  end

  def teardown
    @redis_container.stop if @redis_container
  end
end
```


## Step 3: Connect your RedisBackedCache to the container

Modify the `setup` method to obtain the container's address and port, and use them to create a new instance of your `RedisBackedCache` class:

```ruby
def setup
  @redis_container = Testcontainers::DockerContainer.new("redis:6.2-alpine").with_exposed_ports(6379)
  @redis_container.start
  @redis_container.wait_for_tcp_port(6379)

  host = @redis_container.host
  port = @redis_container.mapped_port(6379)
  @under_test = RedisBackedCache.new(host, port)
end
```


## Step 4: Write your test methods

Now that you have everything set up, you can write your test methods:

```ruby
def test_simple_put_and_get
  @under_test.put("test", "example")
  retrieved = @under_test.get("test")
  assert_equal "example", retrieved
end
```


With these changes, your test suite will automatically start a new Redis container for each test, ensuring a clean and isolated environment. The container will be stopped after each test is completed. You can re-use containers between tests as well (e.g using `after(:suite)` / `before(:suite)` blocks in RSpec).

Take a look to the files [examples/redis_backed_cache_minitest.rb](https://github.com/testcontainers/testcontainers-ruby/blob/main/examples/redis_backed_cache_minitest.rb) and [examples/redis_backed_cache_rspec.rb](https://github.com/testcontainers/testcontainers-ruby/blob/main/examples/redis_backed_cache_rspec.rb) for full examples.
