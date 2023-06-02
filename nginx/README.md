# Testcontainers module for Nginx

testcontainers-nginx simplifies the creation and management of Nginx containers for testing purposes using the Testcontainers library.

## Installation

Add the library to the test section in your application's Gemfile:

```ruby
group :test do
  gem 'testcontainers-nginx'
end
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install testcontainers-nginx
```

## Usage

To use the library, you first need to require it:

```ruby
require 'testcontainers/nginx'
```

### Creating a Nginx container

Create a new instance of the `Testcontainers::NginxContainer` class:

```ruby
container = Testcontainers::NginxContainer.new
```


This creates a new container with the default Nginx image and port. You can customize these by passing arguments to the constructor:

```ruby
container = Testcontainers::MysqlContainer.new("nginx:alpine", port: 8080)
```

You can setup filesystem binds to configure the container with custom configuration files or to serve content from a custom path:

```ruby
container.with_filesystem_binds(["/local/path/custom/conf:/etc/nginx/conf.d:ro"])
container.with_filesystem_binds(["/local/path/custom/content:/usr/share/nginx/html:ro"])
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

### Connecting to the Nginx container

Once the container is running, you can obtain the connection details using the following methods:

```ruby
host = container.host
port = container.first_mapped_port
```


Or, you can generate a full server URL:

```ruby
server_url = container.server_url
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/testcontainers/testcontainers-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Testcontainers project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).
