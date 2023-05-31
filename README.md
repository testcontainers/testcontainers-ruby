# Testcontainers

Testcontainers is a Ruby library that provides a convenient way to run Docker containers for your tests. It is inspired by the popular Testcontainers library for Java.

This library simplifies the process of managing Docker containers during testing, making it easier to ensure a consistent and isolated environment for each test. It supports a wide range of containers, including databases, message queues, and web servers.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add testcontainers

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install testcontainers

## Usage

To use Testcontainers in your tests, first create and start a container in your test setup. For example, to run a Redis container:

```ruby
container = Testcontainers::DockerContainer.new("redis:6.2-alpine").with_exposed_port(6379)
container.start
```



In your tests, you can now access the container's host and mapped port:

```ruby
host = container.host
port = container.mapped_port(6379)
```



This allows you to connect to the containerized service and perform your tests. After running your tests, you can stop and delete the container:


```ruby
container.stop
container.delete
```

For a more detailed example, please refer to the Quickstart Guide under the docs folder.

### Included modules

Tescontainers contains modules that can be used instead of the generic
DockerContainer for common databases and services, providing
pre-configured setups and reducing the amount of boilerplate code.

[ElasticsearchContainer](https://github.com/testcontainers/testcontainers-ruby/tree/main/elasticsearch)

[MariadbContainer](https://github.com/testcontainers/testcontainers-ruby/tree/main/mariadb)

[MongoContainer](https://github.com/testcontainers/testcontainers-ruby/tree/main/mongo)

[MysqlContainer](https://github.com/testcontainers/testcontainers-ruby/tree/main/mysql)

[NginxContainer](https://github.com/testcontainers/testcontainers-ruby/tree/main/nginx)

[PostgresContainer](https://github.com/testcontainers/testcontainers-ruby/tree/main/postgres)

[RedisContainer](https://github.com/testcontainers/testcontainers-ruby/tree/main/redis)

[RedpandaContainer](https://github.com/testcontainers/testcontainers-ruby/tree/main/redpanda)



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/testcontainers/testcontainers-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Testcontainers project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).
