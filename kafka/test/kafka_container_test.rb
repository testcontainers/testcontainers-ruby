# frozen_string_literal: true

require "test_helper"
require "rdkafka"

class KafkaContainerTest < TestcontainersTest
  def before_all
    super

    @container = Testcontainers::KafkaContainer.new
    @container.start
    @container.wait_for_tcp_port(9092)
    @host = @container.host
    @port = @container.mapped_port(9092)
  end

  def after_all
    if @container&.exists?
      @container&.stop if @container&.running?
      @container&.remove
    end

    super
  end

  def test_it_returns_the_default_image
    assert_equal "confluentinc/cp-kafka:7.6.1", @container.image
  end

  def test_it_returns_the_connection_url
    assert_equal "#{@host}:#{@port}", @container.connection_url
  end

  def test_it_returns_bootstrap_servers
    assert_equal "PLAINTEXT://#{@host}:#{@port}", @container.bootstrap_servers
  end

  def test_it_supports_custom_image
    container = Testcontainers::KafkaContainer.new("confluentinc/cp-kafka:7.5.4")
    assert_equal "confluentinc/cp-kafka:7.5.4", container.image
  end

  def test_it_is_reachable
    config = {
      "bootstrap.servers": @container.connection_url,
      "group.id": "ruby-test",
      "auto.offset.reset": "earliest"
    }

    producer = Rdkafka::Config.new(config).producer
    producer.produce(payload: "Hello, Kafka!", topic: "ruby-test-topic").wait

    consumer = Rdkafka::Config.new(config).consumer
    consumer.subscribe("ruby-test-topic")

    message = consumer.each do |msg|
      break msg
    end

    assert_equal "Hello, Kafka!", message.payload
    assert_equal "ruby-test-topic", message.topic
  end
end
