# Testcontainers module for Compose

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
### Creating a Compose service

Create a new instance of the `Testcontainers::ComposeContainer` class:
``` ruby
compose = Testcontainer::ComposeContainer.new(filepath: Dir.getwd)
```	
The instance creates a set of containers defined on the .yml file, the 'compose.start' wakes up all containers as service

Start the services of compose 

```ruby
compose.start
```


Stop the services of compose
```ruby
compose.stop
```
### Connecting to services from the compose

Once the service is running , tu can obtain the connecion details using the fol	lowing methods 

```ruby
compose.process_information(service: "hub", port: 4444)
```
This function will show the logs of the process

```ruby
compose.logs
```

To wait for a service running on a url you should use 'wait_for_request':

```ruby
compose.wait_for_request(url: "http://localhost:4444/hub")
```

### Configuration of services

next example initialize compose with two services described in the YML file located in the current directory

```ruby
services = ["hub","firefox"]
compose = Testcontainers::ComposeContainer.new(filepath: Dir.getwd, services: services)
```

In this example we ll make a  continer by specific .yml files

```ruby
compose_filename = ["docker-compose2.yml", "docker-compose3.yml"]
compose = Testcontainer::ComposeContainer.new(filepath: Dir.getwd, compose_filename: compose_filename)
compose.start


```
You can overwrite an enviorement file as next:

```ruby
TEST_PATH = "#{Dir.getwd}/test"
compose_filename = ["docker-compose3.yml"]
compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, compose_filename: compose_filename, env_file: ".env.test")
```

### Send commands for the compose service 
```ruby
compose.run_in_container(service_name: "hub", command: "echo test")
```



###



## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/testcontainers/testcontainers-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


## Code of Conduct


Everyone interacting in the Testcontainers project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).
