# Testcontainers module for Redpanda

## Installation

Add the library to the test section in your application's Gemfile:

```ruby
group :test do
  gem 'testcontainers-redpanda'
end
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install testcontainers-redpanda
```

## Usage

### Creating a Redpanda container

Create a new instance of the `Testcontainers::RedpandaContainer` class:

```ruby
container = Testcontainers::RedpandaContainer.new
```


This creates a new container with the default MariaDB image. You can customize it by passing arguments to the constructor:

```ruby
container = Testcontainers::MariadbContainer.new("vectorized/redpanda")
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

### Connecting to the Redpanda container

Once the container is running, you can obtain the connection details using the following methods:

```ruby
host = container.host
port = container.mapped_port(9092)
```

or

```ruby
connection_url = container.connection_url
```


Use these connection details to connect to the Redpanda container using your preferred Kafka client library.



### Example

Here's a complete example of how to use testcontainers-redpanda to create a container, connect an consumer and a producer to it, and deliver one message:

```ruby
require "testcontainers/redpada"
require "rdkafka"

container = Testcontainers::RedpandaContainer.new
container.start

config = {
  "bootstrap.servers": container.connection_url,
  "group.id": "ruby-test"
}

consumer = Rdkafka::Config.new(config).consumer
consumer.subscribe("ruby-test-topic")

producer = Rdkafka::Config.new(config).producer
producer.produce(payload: "Hello, Redpanda!", topic: "ruby-test-topic").wait

message = consumer.each do |msg|
  break msg
end

puts msg.inspect

container.stop
```

### Using with RSpec

You can manage the Redpanda container in the before(:suite) / after(:suite) blocks in your spec_helper.rb:

```ruby
RSpec.configure do |config|
  # This helps us to have access to the `RSpec.configuration.redpanda_container` without using global variables.
  config.add_setting :redpanda_container, default: nil

  config.before(:suite) do
    config.redpanda_container = Testcontainers::RedpandaContainer.new.start
    # Use the container connection details in your tests
  end

  config.after(:suite) do
    config.redpanda_container&.stop
    config.redpanda_container&.remove
  end
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/guilleiguaran/testcontainers. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/guilleiguaran/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Testcontainers project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/guilleiguaran/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).
