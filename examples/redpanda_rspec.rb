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
    config = {
      "bootstrap.servers": RSpec.configuration.redpanda_container.connection_url,
      "group.id": "ruby-test",
      "auto.offset.reset": "earliest"
    }

    producer = Rdkafka::Config.new(config).producer
    producer.produce(payload: "test", topic: "ruby-test-topic").wait

    consumer = Rdkafka::Config.new(config).consumer
    consumer.subscribe("ruby-test-topic")

    consumer.each do |message|
      expect(message.payload).to eq("test")
      break
    end
  end
end
