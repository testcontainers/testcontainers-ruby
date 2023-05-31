# Testcontainers module for MongoDB

testcontainers-mongo simplifies the creation and management of MongoDB containers for testing purposes using the Testcontainers library.

## Installation

Add the library to the test section in your application's Gemfile:

```ruby
group :test do
  gem "testcontainers-mongo"
end
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install testcontainers-mongo
```

## Usage

To use the library, you first need to require it:

```ruby
require "testcontainers/mongo"
```

### Creating a MongoDB container

Create a new instance of the `Testcontainers::MongoContainer` class:

```ruby
container = Testcontainers::MongoContainer.new
```

This creates a new container with the default MongoL image, user, password, and database. You can customize these by passing arguments to the constructor:

```ruby
container = Testcontainers::MongoContainer.new("mongo:5.7", username: "custom_user", password: "custom_pass", database: "custom_db")
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

### Connecting to the MongoDB container

Once the container is running, you can obtain the connection details using the following methods:

```ruby
host = container.host
port = container.first_mapped_port
```

Or, you can generate a full database URL:

```ruby
database_url = container.database_url
```

Use this URL to connect to the MongoDB container using your preferred MongoDB client library.

### Customizing the container

You can also customize the container using the following methods:

```ruby
container.with_database("custom_db")
container.with_username("custom_user")
container.with_password("custom_pass")
```

### Example

Here's a complete example of how to use testcontainers-mongo to create a container, connect to it, and run a simple query:

```ruby
require "testcontainers/mongo"
require "mongo"

container = Testcontainers::MongoContainer.new
container.start

client = Mongo::Client.new(container.database_url, auth_source: "admin")

client[:artists].insert_one({:name => "FKA Twigs"})
client[:artists].find(:name => "FKA Twigs").each do |document|
  document.inspect
end

client.close
container.stop
```

This example creates a MongoDB container, connects to it using the `mongo` gem, inserts a a document, runs a query with find, and then stops the container.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/guilleiguaran/testcontainers. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Testcontainers project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).
