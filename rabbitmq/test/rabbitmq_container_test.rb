# frozen_string_literal: true

require "test_helper"
require "bunny"

class RabbitmqContainerTest < TestcontainersTest
  def before_all
    super

    @container = Testcontainers::RabbitmqContainer.new
    @container.start
    @host = @container.host
    @port = @container.first_queue_mapped_port
  end

  def after_all
    if @container&.exists?
      @container&.stop if @container&.running?
      @container&.remove
    end

    super
  end

  def test_it_returns_the_default_image
    assert_equal "rabbitmq:latest", @container.image
  end

  def test_it_supports_custom_image
    container = Testcontainers::RabbitmqContainer.new("mariadb:latest")
    assert_equal "mariadb:latest", container.image
  end

  def test_it_returns_the_default_port_to_enqueue_messages
    assert_equal 5672, @container.queue_port
  end

  def test_it_returns_the_default_port_to_add_plugins
    assert_equal 15672, @container.plugins_port
  end

  def test_it_is_configured_with_the_default_environment_variables
    assert "test", @container.get_env("RABBITMQ_DEFAULT_VHOST")
    assert "test", @container.get_env("RABBITMQ_DEFAULT_USER")
    assert "test", @container.get_env("RABBITMQ_DEFAULT_PASSWORD")
  end

  def test_it_has_the_default_port_mapped
    assert @container.mapped_port(5672)
  end

  def test_it_supports_custom_keyword_arguments
    container = Testcontainers::RabbitmqContainer.new(filesystem_binds: ["#{Dir.pwd}/custom/conf:/var/lib/postgresql/data/postgresql.conf:rw"])
    assert_equal ["#{Dir.pwd}/custom/conf:/var/lib/postgresql/data/postgresql.conf:rw"], container.filesystem_binds
  end

  def test_it_returns_the_default_rabbitmq_url
    assert_equal "amqp://test:test@#{@host}:#{@port}/test", @container.rabbitmq_url
  end

  def test_it_returns_the_rabbitmq_url_with_custom_vhost
    assert_equal "amqp://test:test@#{@host}:#{@port}/foo", @container.rabbitmq_url(vhost: "foo")
  end

  def test_it_returns_the_rabbitmq_url_with_custom_protocol
    assert_equal "amqps://test:test@#{@host}:#{@port}/test", @container.rabbitmq_url(protocol: "amqps")
  end

  def test_it_returns_the_rabbitmq_url_with_custom_username
    assert_equal "amqp://foo:test@#{@host}:#{@port}/test", @container.rabbitmq_url(username: "foo")
  end

  def test_it_returns_the_rabbitmq_url_with_custom_password
    assert_equal "amqp://test:bar@#{@host}:#{@port}/test", @container.rabbitmq_url(password: "bar")
  end

  def test_it_is_reachable
    @container.wait_for_logs(/Ready to start client connection listeners/)
    connection = Bunny.new(host: @host, port: @port, user: "test", pass: "test", vhost: "test")
    connection.start
    channel = connection.create_channel
    queue = channel.queue("hello")
    channel.default_exchange.publish("Hello World!", routing_key: queue.name)

    assert_equal 1, queue.message_count
    connection.close
  end
end
