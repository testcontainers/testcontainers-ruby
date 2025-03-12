# Testcontainers module for RabbitMQ

## Installation

Add the library to the test section in your application's Gemfile:

```ruby
group :test do
  gem 'testcontainers-rabbitmq'
end
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install testcontainers-rabbitmq
```

## Usage

To use the library, you first need to require it:

```ruby
require "testcontainers/rabbitmq"
```

### Creating a RabbitMQ container

Create a new instance of the `Testcontainers::RabbitmqContainer` class:

```ruby
container = Testcontainers::RabbitmqContainer.new
```

This creates a new container with the default RabbitMQ image, user, password, and vhost. You can customize these by passing arguments to the constructor:

```ruby
container = Testcontainers::RabbitmqContainer.new("rabbitmq:latest", username: "custom_user", password: "custom_pass", vhost: "custom_vhost")
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

### Connecting to the RabbitMQ container

Once the container is running, you can obtain the connection details using the following methods:

```ruby
host = container.host
port = container.first_mapped_port
```

Or, you can generate a full RabbitMQ URL:

```ruby
broker_url = container.rabbitmq_url
```

### Customizing the container

```ruby
container.with_vhost("custom_vhost")
container.with_username("custom_user")
container.with_password("custom_pass")
```

### Example

There are complete examples of how to use testcontainers-rabbitmq to create containers, connects to it, publish and consume simple message:

```ruby
require "testcontainers/rabbitmq"
require "bunny"

container = Testcontainers::RabbitmqContainer.new
container.start

connection = Bunny.new(container.rabbitmq_url)
connection.start

channel = connection.create_channel
queue = channel.queue('hello')
channel.default_exchange.publish('Hello World!', routing_key: queue.name)

connection.close
```

The previous example creates a RabbitMQ container, connects to it using `bunny` gem, then publish a message to a queue named `hello`

```ruby
require "testcontainers/rabbitmq"
require "bunny"

container = Testcontainers::RabbitmqContainer.new
container.start

connection = Bunny.new(container.rabbitmq_url)
connection.start

channel = connection.create_channel
queue = channel.queue('hello')

queue.subscribe(block: true) do |_delivery_info, _properties, body|
  puts " [x] Received #{body}"
end

connection.close
```

The previous example creates a RabbitMQ container, connects to it using `bunny` gem, then reads messages from a queue named `hello`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/testcontainers/testcontainers-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Testcontainers project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).
