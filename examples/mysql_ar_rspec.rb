require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "rspec"
  gem "testcontainers-core", path: "../core"
  gem "testcontainers-mysql", path: "../mysql"
  gem "activerecord"
  gem "mysql2"
end

require "active_record"
require "logger"
require "rspec"
require "rspec/autorun"
require "testcontainers/mysql"

RSpec.configure do |config|
  config.before(:suite) do
    config.add_setting :mysql, default: nil

    container = Testcontainers::MysqlContainer.new(database: "posts_test")
    container.with_healthcheck(test: ["/usr/bin/mysql", "--user=test", "--password=test", "--execute", "SHOW DATABASES;"], interval: 1, timeout: 1, retries: 5)
    container.start
    container.wait_for_healthcheck
    config.mysql = container

    ENV["DATABASE_URL"] = container.database_url(protocol: "mysql2")

    # In your own tests, you would probably put this ENV["DATABASE_URL"] in your database.yml file instead
    ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"])

    # Schema required for the demo, ignore in your own tests
    ActiveRecord::Schema.define do
      create_table :posts, force: true do |t|
      end
    end

    # Ignore in your own tests
    ActiveRecord::Base.logger = Logger.new($stdout)
  end

  config.after(:suite) do
    config.mysql&.stop if config.mysql&.running?
    config.mysql&.remove
  end
end

class Post < ActiveRecord::Base
end

RSpec.describe Post do
  it "create new posts" do
    Post.create!
    expect(Post.count).to eq(1)
  end
end
