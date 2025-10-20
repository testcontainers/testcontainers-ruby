# Testcontainers module for Kafka

## Installation

Add the library to the test section in your application's Gemfile:

```ruby
group :test do
  gem 'testcontainers-kafka'
end
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install testcontainers-kafka
```

## Usage

```ruby
require "testcontainers/kafka"
require "rdkafka"

container = Testcontainers::KafkaContainer.new.start

begin
  container.wait_for_tcp_port(9092)
  config = {
    "bootstrap.servers": container.connection_url,
    "group.id": "ruby-example",
    "auto.offset.reset": "earliest"
  }

  producer = Rdkafka::Config.new(config).producer
  producer.produce(payload: "hello", topic: "example").wait

  consumer = Rdkafka::Config.new(config).consumer
  consumer.subscribe("example")
  puts consumer.each { |msg| break msg.payload }
ensure
  container.stop if container.running?
  container.remove if container.exists?
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/testcontainers/testcontainers-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Testcontainers project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).
