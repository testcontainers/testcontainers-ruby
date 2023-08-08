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
The instance creates a set of containers defined on the .yml file, the 'container.start' wakes up all containers as service

Start the services of compose 

```ruby
compose.start
```


Stop the services of compose
```ruby
compose.stop
```
### Connecting to services from the compose

Once the service is running , tu can obtain the connecion details using the following methods 

```ruby
compose.process_information(service: "hub", port: 4444)
```
This function gonna show the logs of the process

```ruby
compose.logs
```
This function make a request for the url nested for the service from compose


```ruby
compose.wait_for_request(url: )
```

### Configuration of services
In this example we re gonna make a container with two services that use the yml files in the current path

```ruby
services = ["hub","firefox"]
container = Testcontainers::ComposeContainer.new(filepath: Dir.getwd, services: services)
```

In this example we re gonna make a  continer by specific .yml files

```ruby
compose_file_name = ["docker-compose2.yml", "docker-compose2.yml"]
compose = Testcontainer::ComposeContainer.new(filepath: Dir.getwd, compose_file_name: compose_file_name)
compose.start


```
In this example we re gonna make a container with a enviorement variables configuration file


```ruby
compose_file_name = ["docker-compose3.yml"]
compose = Testcontainers::ComposeContainer.new(filepath: TEST_PATH, compose_file_name: compose_file_name, env_file: ".env.test")
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
