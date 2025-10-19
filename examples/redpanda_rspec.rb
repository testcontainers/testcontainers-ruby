require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "testcontainers-core", path: "../core"
  gem "testcontainers-redpanda", path: "../redpanda"

  gem "rspec"
  gem "rdkafka"
end

require "rdkafka"
require "rspec"
require "rspec/autorun"
require "timeout"

RSpec.configure do |config|
  config.add_setting :redpanda_container, default: nil

  config.before(:suite) do
    config.redpanda_container = Testcontainers::RedpandaContainer.new.start
  end

  config.after(:suite) do
    config.redpanda_container&.stop if config.redpanda_container&.running?
    config.redpanda_container&.remove
  end
end

RSpec.describe "Redpanda" do
  it "works" do
    topic = "ruby-test-topic"
    producer_config = {
      "bootstrap.servers": RSpec.configuration.redpanda_container.connection_url,
      "message.timeout.ms": 10_000
    }
    consumer_config = {
      "bootstrap.servers": RSpec.configuration.redpanda_container.connection_url,
      "group.id": "ruby-test",
      "auto.offset.reset": "earliest"
    }

    producer = nil
    consumer = nil

    begin
      producer = Rdkafka::Config.new(producer_config).producer
      consumer = Rdkafka::Config.new(consumer_config).consumer
      consumer.subscribe(topic)

      producer.produce(payload: "test", topic: topic).wait

      message = nil
      begin
        Timeout.timeout(15) do
          loop do
            message = consumer.poll(1000)
            break if message
          end
        end
      rescue Timeout::Error
        fail "Timed out waiting for message on #{topic}"
      end

      expect(message.payload).to eq("test")
    ensure
      producer&.flush(5_000)
      producer&.close
      consumer&.close
    end
  end
end
