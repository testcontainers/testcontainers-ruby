# Testcontainers module for Postgres

testcontainers-postgres simplifies the creation and management of Postgres containers for testing purposes using the Testcontainers library.

## Installation

Add the library to the test section in your application's Gemfile:

```ruby
group :test do
  gem 'testcontainers-postgres'
end
```



And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install testcontainers-postgres
```


## Usage

To use the library, you first need to require it:

```ruby
require 'testcontainers/postgres'
```

### Creating a Postgres container

Create a new instance of the `Testcontainers::PostgresContainer` class:

```ruby
container = Testcontainers::PostgresContainer.new
```



This creates a new container with the default Postgres image, user, password, and database. You can customize these by passing arguments to the constructor:

```ruby
container = Testcontainers::PostgresContainer.new("postgres:11", username: "custom_user", password: "custom_pass", database: "custom_db")
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


### Connecting to the Postgres container

Once the container is running, you can obtain the connection details using the following methods:

```ruby
host = container.host
port = container.first_mapped_port
```



Or, you can generate a full database URL:

```ruby
database_url = container.database_url
```

Use this URL to connect to the Postgres container using your preferred postgres client library.

### Customizing the container

You can also customize the container using the following methods:

```ruby
container.with_database("custom_db")
container.with_username("custom_user")
container.with_password("custom_pass")
```

### Example

Here's a complete example of how to use testcontainers-postgres to create a container, connect to it, and run a simple query:

```ruby
require 'testcontainers/postgres'
require 'pg'

container = Testcontainers::PostgresContainer.new
container.start

client = PG.connect(container.database_url)

result = client.exec("SELECT 1 AS number")
result.each do |row|
  puts row.inspect
end

client.close
container.stop
```

This example creates a Postgres container, connects to it using the `pg` gem, runs a simple `SELECT 1 as number` query, and then stops the container.

### Example with RSpec

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/guilleiguaran/testcontainers. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/guilleiguaran/testcontainers/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Testcontainers project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/guilleiguaran/testcontainers/blob/main/CODE_OF_CONDUCT.md).
