# Testcontainers module for Selenium

## Installation

Add the library to the test section in your application's Gemfile:

```ruby
group :test do
  gem 'testcontainers-selenium'
end
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install testcontainers-selenium
```

## Usage

To use the library, you first need to require it:

```ruby
require "testcontainers/selenium"
```


### Creating a Selenium Container

Create a new instance of the `Testcontainers::SeleniumContainer` class:

```ruby
container = Testcontainer::SeleniumContainer.new
```

This creates a new container with the default Selenium configuration for firefox, the vnc password will be `secret`. You can customise by passing arguments to the constructor:

```ruby
container = Testcontainer::SeleniumContainer.new(capabilities: :chrome, vnc_no_password: true)
```

### Starting and Stopping a container 

Start the container

```ruby
container.start
```

Stop the container when you're done

```ruby
container.stop
```

### Connecting to the Selenium container 

Once the container is running, you can obtain the connection details using the following methods:


```ruby
host = container.host
post = container.first_mapped_port
```

Or, you can generate a full Selenium URL


```ruby
selenium_url = container.selenium_url
```

### Examples

There are complete examples of how to use testcontainers-selenium to create containers, connects to it, and navigate through different browsers:


```ruby
require "testcontainers/selenium"
require "selenium-webdriver"

container = Testcontainer::SeleniumContainer.new
container.start

driver = Selenium::WebDriver.for(:firefox, :url => @container.selenium_url)

driver.navigate.to "https://www.google.com"

driver.screenshot
```

The previous example creates a container and after create a client for do a connections wiht the google page,finally we take a screenshot from the current page

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/testcontainers/testcontainers-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Testcontainers project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/testcontainers/testcontainers-ruby/blob/main/CODE_OF_CONDUCT.md).
