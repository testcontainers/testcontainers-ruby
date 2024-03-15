# Testcontainers module for Docker Compose

## Installation

Add the library to the test section in your application's Gemfile:

```ruby
group :test do
  gem 'testcontainers-compose'
end
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install testcontainers-compose
```

## Usage
To use the library, you first need to require it:

```ruby
require "testcontainers/compose"
```

### Creating a Compose Container
Create a new instance of the `Testcontainers::ComposeContainer` class:

``` ruby
compose = Testcontainers::ComposeContainer.new(filepath: Dir.getwd)
```

The instance creates a set of containers defined on the .yml file, the 'compose.start' wakes up all containers as service

Start the services on the compose file.

```ruby
compose.start
```

Stop the services:

```ruby
compose.stop
```

### Connecting to services

Once the service is running, you can obtain the mapped port to connect to it:

```ruby
compose.service_port(service: "hub", port: 4444)
```

You can inspect the logs of for the services also:

```ruby
puts compose.logs
```

You can use `wait_for_logs`, `wait_for_http` and `wait_for_tcp_port` to wait for the services to start:

```ruby
compose.wait_for_logs(/Service started/)
compose.wait_for_http(url: "http://localhost:4444/hub")
compose.wait_for_tcp_port(host: "localhost", port: 3306)
```

### Configuration of services

This example initialize docker compose with two services described in the YML file located in the current directory:

```ruby
services = ["hub","firefox"]
compose = Testcontainers::ComposeContainer.new(filepath: Dir.getwd, services: services)
```

You can specify the name of different docker-compose files also:

```ruby
compose_filenames = ["docker-compose.dbs.yml", "docker-compose.web.yml"]
compose = Testcontainers::ComposeContainer.new(filepath: Dir.getwd, compose_filenames: compose_filenames)
compose.start
```

An env file can be specified when starting the services:

```ruby
compose_filename = ["docker-compose.test.yml"]
compose = Testcontainers::ComposeContainer.new(filepath: Dir.getwd, env_file: ".env.test")
```

### Executing commands in the container for a service

```ruby
compose.exec(service_name: "hub", command: "echo test")
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/testcontainers/testcontainers-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


## Code of Conduct

Everyone interacting in the Testcontainers project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).
