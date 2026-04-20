require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "testcontainers-core", path: "../core"
  gem "testcontainers-clickhouse", path: "../clickhouse"

  gem "rspec"
  gem "clickhouse-activerecord"
  gem "activerecord", "~> 7.2"
end

require "active_record"
require "clickhouse-activerecord"
require "rspec"
require "rspec/autorun"

RSpec.configure do |config|
  config.add_setting :clickhouse_container, default: nil

  config.before(:suite) do
    config.clickhouse_container = Testcontainers::ClickhouseContainer.new.start
  end

  config.after(:suite) do
    config.clickhouse_container&.stop if config.clickhouse_container&.running?
    config.clickhouse_container&.remove
  end
end

class Event < ActiveRecord::Base
  self.abstract_class = true
end

RSpec.describe "Clickhouse" do
  before(:all) do
    container = RSpec.configuration.clickhouse_container
    ActiveRecord::Base.establish_connection(
      adapter: "clickhouse",
      host: container.host,
      port: container.mapped_port(container.http_port),
      database: container.database,
      username: container.username,
      password: container.password
    )

    ActiveRecord::Base.connection.create_table :events, id: false, options: "ENGINE = Memory" do |t|
      t.string :name, null: false
    end
  end

  it "inserts and queries rows" do
    Event.create!(name: "test")
    expect(Event.count).to eq(1)
    expect(Event.first.name).to eq("test")
  end
end
