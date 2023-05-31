# Testcontainers module for Redis

`testcontainers-redis` simplifies the creation and management of Redis containers for testing purposes using the Testcontainers library.

## Installation

Add the library to the test section in your application's Gemfile:

```ruby
group :test do
  gem 'testcontainers-redis'
end
```



And then execute:

```bash
$ bundle install
```



Or install it yourself as:

```bash
$ gem install testcontainers-redis
```


## Usage

To use the library, you first need to require it:

```ruby
require 'testcontainers/redis'
```


### Creating a Redis container

Create a new instance of the `Testcontainers::RedisContainer` class:

```ruby
container = Testcontainers::RedisContainer.new
```



This creates a new container with the default Redis image. You can customize these by passing arguments to the constructor:

```ruby
container = Testcontainers::RedisContainer.new("redis:6.0-alpine", password: "custom_pass")
```


### Starting and stopping the container

Start the container:

```ruby
container.start
```



Stop the container when you're done:

```ruby
container.stop
```


### Connecting to the Redis container

Once the container is running, you can obtain the connection details using the following methods:

```ruby
host = container.host
port = container.first_mapped_port
```



Or, you can generate a full Redis URL:

```ruby
redis_url = container.redis_url
```

Use this URL to connect to the Redis container using your preferred Redis client library.

### Customizing the container

You can also customize the container before of starting it, e.g setting a custom password for
client's authentication:

```ruby
container.with_password("custom_pass")
```

or using a custom `redis.conf` (saved under `$PWD/custom/conf` in this
example):

```ruby
container.with_filesystem_binds(["#{Dir.pwd}/custom/conf:/usr/local/etc/redis:rw"])
container.with_cmd("redis-server /usr/local/etc/redis/redis.conf")
```

### Example

Here's a complete example of how to use `testcontainers-redis` to create a container, connect to it, and run a simple command:

```ruby
require 'testcontainers/redis'
require 'redis'

container = Testcontainers::RedisContainer.new
container.start

client = Redis.new(url: container.redis_url)

client.set("mykey", "hello world")
value = client.get("mykey")

puts value

client.quit
container.stop
```

This example creates a Redis container, connects to it using the `redis` gem, sets and retrieves a key-value pair, and then stops the container.

### Example with RSpec

Take a look to the files [examples/redis_container_rspec.rb](https://github.com/testcontainers/testcontainers-ruby/blob/main/examples/redis_container_rspec.rb) for a example using RSpec.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/guilleiguaran/testcontainers. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Testcontainers project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).
