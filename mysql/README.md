# Testcontainers module for MySQL

testcontainers-mysql simplifies the creation and management of MySQL containers for testing purposes using the Testcontainers library.

## Installation

Add the library to the test section in your application's Gemfile:

```ruby
group :test do
  gem 'testcontainers-mysql'
end
```



And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install testcontainers-mysql
```


## Usage

To use the library, you first need to require it:

```ruby
require 'testcontainers/mysql'
```

### Creating a MySQL container

Create a new instance of the `Testcontainers::MysqlContainer` class:

```ruby
container = Testcontainers::MysqlContainer.new
```



This creates a new container with the default MySQL image, user, password, and database. You can customize these by passing arguments to the constructor:

```ruby
container = Testcontainers::MysqlContainer.new("mysql:5.7", username: "custom_user", password: "custom_pass", database: "custom_db")
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


### Connecting to the MySQL container

Once the container is running, you can obtain the connection details using the following methods:

```ruby
host = container.host
port = container.first_mapped_port
```



Or, you can generate a full database URL:

```ruby
database_url = container.database_url
```

Use this URL to connect to the MySQL container using your preferred MySQL client library.

### Customizing the container

You can also customize the container using the following methods:

```ruby
container.with_database("custom_db")
container.with_username("custom_user")
container.with_password("custom_pass")
```

### Example

Here's a complete example of how to use testcontainers-mysdql to create a container, connect to it, and run a simple query:

```ruby
require 'testcontainers/mysql'
require 'mysql2'

container = Testcontainers::MysqlContainer.new
container.start

client = Mysql2::Client.new(url: container.database_url)

result = client.query("SELECT 1")
result.each do |row|
  puts row.inspect
end

client.close
container.stop
```

This example creates a MySQL container, connects to it using the `mysql2` gem, runs a simple `SELECT 1` query, and then stops the container.

### Example with RSpec

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/guilleiguaran/testcontainers. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/guilleiguaran/testcontainers/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Testcontainers project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/guilleiguaran/testcontainers/blob/main/CODE_OF_CONDUCT.md).
