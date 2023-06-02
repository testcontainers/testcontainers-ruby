# frozen_string_literal: true

require "test_helper"
require "bunny"

class RabbitmqContainerTest < TestcontainersTest
  def before_all
    super

    @container = Testcontainers::RabbitmqContainer.new
    @container.start
    @host = @container.host
    @port = @container.first_mapped_port
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
    container = Testcontainers::RabbitmqContainer.new("rabbitmq:management")
    assert_equal "rabbitmq:management", container.image
  end

  def test_it_returns_the_default_port_for_queues
    assert_equal 5672, @container.port
  end

  def test_it_returns_the_default_port_for_management_ui
    assert_equal 15672, @container.management_ui_port
  end

  def test_it_is_configured_with_the_default_environment_variables
    assert_equal "rabbitmq", @container.get_env("RABBITMQ_DEFAULT_USER")
    assert_equal "rabbitmq", @container.get_env("RABBITMQ_DEFAULT_PASS")
    assert_equal "/", @container.get_env("RABBITMQ_DEFAULT_VHOST")
  end

  def test_it_has_the_default_port_mapped
    assert @container.mapped_port(5672)
  end

  def test_it_supports_custom_keyword_arguments
    container = Testcontainers::RabbitmqContainer.new(env: {"RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS" => "foo"})
    assert_equal "foo", container.get_env("RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS")
  end

  def test_it_returns_the_default_rabbitmq_url
    assert_equal "amqp://rabbitmq:rabbitmq@#{@host}:#{@port}", @container.rabbitmq_url
  end

  def test_it_returns_the_rabbitmq_url_with_custom_vhost
    assert_equal "amqp://rabbitmq:rabbitmq@#{@host}:#{@port}/foo", @container.rabbitmq_url(vhost: "foo")
  end

  def test_it_returns_the_rabbitmq_url_with_custom_vhost_with_slash
    assert_equal "amqp://rabbitmq:rabbitmq@#{@host}:#{@port}/bar", @container.rabbitmq_url(vhost: "/bar")
  end

  def test_it_returns_the_rabbitmq_url_with_custom_protocol
    assert_equal "amqps://rabbitmq:rabbitmq@#{@host}:#{@port}", @container.rabbitmq_url(protocol: "amqps://")
  end

  def test_it_returns_the_rabbitmq_url_with_custom_username
    assert_equal "amqp://foo:rabbitmq@#{@host}:#{@port}", @container.rabbitmq_url(username: "foo")
  end

  def test_it_returns_the_rabbitmq_url_with_custom_password
    assert_equal "amqp://rabbitmq:bar@#{@host}:#{@port}", @container.rabbitmq_url(password: "bar")
  end

  def test_it_is_reachable
    @container.wait_for_logs(/Ready to start client connection listeners/)
    connection = Bunny.new(@container.rabbitmq_url)
    connection.start
    channel = connection.create_channel
    queue = channel.queue("hello")
    channel.default_exchange.publish("Hello World!", routing_key: queue.name)

    assert_equal 1, queue.message_count
    connection.close
  end
end
