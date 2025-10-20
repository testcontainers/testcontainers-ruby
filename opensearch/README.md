# Testcontainers module for Opensearch

## Installation

Add the library to the test section in your application's Gemfile:

```ruby
group :test do
  gem 'testcontainers-opensearch'
end
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install testcontainers-opensearch
```

## Usage

```ruby
require "testcontainers/opensearch"

container = Testcontainers::OpensearchContainer.new.start

begin
  container.wait_for_healthcheck
  client = OpenSearch::Client.new(url: container.opensearch_url)
  client.ping # => true
ensure
  container.stop if container.running?
  container.remove if container.exists?
end
```

The container exposes ports 9200 (HTTP) and 9600 (metrics) by default and
disables the security plugin so you can connect without credentials. Override
environment variables via `with_env` before calling `start` if you need to
change the defaults.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/testcontainers/testcontainers-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Testcontainers project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).
