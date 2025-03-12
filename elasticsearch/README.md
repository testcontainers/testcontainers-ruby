# Testcontainers module for Elasticsearch

testcontainers-elasticsearch simplifies the creation and management of ElasticSearch containers for testing purposes using the Testcontainers library.

## Installation

Add the library to the test section in your application's Gemfile:

```ruby
group :test do
  gem 'testcontainers-elasticsearch'
end
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install testcontainers-elasticsearch
```

## Usage

To use the library, you first need to require it:

```ruby
require "testcontainers/elasticsearch"
```

### Creating an Elasticsearch container

Create a new instance of the `Testcontainers::ElasticsearchContainer` class:

```ruby
container = Testcontainers::ElasticsearchContainer.new
```

This creates a new container with the default Elasticsearch image. You can customize the image by passing an argument to the constructor:

```ruby
container = Testcontainers::ElasticsearchContainer.new("elasticsearch:7.17.10")
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

### Connecting to the Elasticsearch container

Once the container is running, you can obtain the connection details using the following methods:

```ruby
host = container.host
port = container.first_mapped_port
```

Or, you can generate the full Elasticsearch URL:

```ruby
elasticsearch_url = container.elasticsearch_url
```

Use this URL to connect to the Elasticsearch container using your preferred Elasticsearch client library.

### Example

Here's a complete example of how to use testcontainers-elasticsearch to create a container, connect to it, and perform a simple health check:

```ruby
require "testcontainers/elasticsearch"
require "elasticsearch"

container = Testcontainers::ElasticsearchContainer.new
container.start

client = Elasticsearch::Client.new(url: ccontainer.elasticsearch_url)
client.ping #=> true

container.stop
```

This example creates an Elasticsearch container, connects to it using the `elasticsearch` library, performs a simple ping, and then stops the container.


### Using with RSpec

You can manage the container in the `before(:suite)` / `after(:suite)` blocks in your `spec_helper.rb`:

```ruby
RSpec.configure do |config|
  # This helps us to have access to the `RSpec.configuration.elasticsearch_container` without using global variables.
  config.add_setting :elasticsearch_container, default: nil

  config.before(:suite) do
    config.elasticsearch_container = Testcontainers::ElasticsearchContainer.new.start
    ENV["ELASTICSEARCH_URL"] = config.elasticsearch_container.elasticsearch_url
  end

  config.after(:suite) do
    config.elasticsearch_container&.stop
    config.elasticsearch_container&.remove
  end
end
```

This code starts an Elasticsearch container before the test suite runs and stops it after the suite finishes. The Elasticsearch URL is stored in an environment variable, so it's accessible to the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/testcontainers/testcontainers-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Testcontainers project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).
