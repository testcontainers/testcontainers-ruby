# Testcontainers module for MariaDB

## Installation

Add the library to the test section in your application's Gemfile:

```ruby
group :test do
  gem "testcontainers-mariadb"
end
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install testcontainers-mariadb
```

## Usage

To use the library, you first need to require it:

```ruby
require "testcontainers/mariadb"
```

### Creating a MariaDB container

Create a new instance of the `Testcontainers::MariadbContainer` class:

```ruby
container = Testcontainers::MariadbContainer.new
```


This creates a new container with the default MariaDB image, user, password, and database. You can customize these by passing arguments to the constructor:

```ruby
container = Testcontainers::MariadbContainer.new("mariadb:10.10", username: "custom_user", password: "custom_pass", database: "custom_db")
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

### Connecting to the MariaDB container

Once the container is running, you can obtain the connection details using the following methods:

```ruby
host = container.host
port = container.first_mapped_port
```


Or, you can generate a full database URL:

```ruby
database_url = container.database_url
```

Use this URL to connect to the MariaDB container using your preferred MySQL client library.

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
require "testcontainers/mariadb"
require "mysql2"

container = Testcontainers::MariadbContainer.new
container.start

client = Mysql2::Client.new(url: container.database_url)

result = client.query("SELECT 1")
result.each do |row|
  puts row.inspect
end

client.close
container.stop
```

This example creates a MariaDB container, connects to it using the `mysql2` gem, runs a simple `SELECT 1` query, and then stops the container.

### Using with RSpec

You can manage the container in the `before(:suite)` / `after(:suite)` blocks in your `spec_helper.rb`:

```ruby
RSpec.configure do |config|
  # This helps us to have access to the `RSpec.configuration.mariadb_container` without using global variables.
  config.add_setting :mariadb_container, default: nil

  config.before(:suite) do
    config.mariadb_container = Testcontainers::MariadbContainer.new.start
    ENV["DATABASE_URL"] = config.mariadb_container.database_url(protocol: "mysql2") # or you can expose it to a fixed port and use database.yml for configuration
  end

  config.after(:suite) do
    config.mariadb_container&.stop
    config.mariadb_container&.remove
  end
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/guilleiguaran/testcontainers. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/guilleiguaran/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Testcontainers project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/guilleiguaran/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).
