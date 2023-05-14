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
  config.add_setting :mysql_container, default: nil
  config.add_setting :database_url, default: nil

  config.before(:suite) do
    container = Testcontainers::MysqlContainer.new(database: "posts_test").start
    config.mysql_container = container
    # On your own tests, you would probably save this url on ENV["DATABASE_URL"] and point to it in your database.yml file
    # ENV["DATABASE_URL"] = container.database_url(protocol: "mysql2")
    config.database_url = container.database_url(protocol: "mysql2")
  end

  config.after(:suite) do
    config.mysql_container&.stop if config.mysql_container&.running?
    config.mysql_container&.remove
  end
end

class Post < ActiveRecord::Base
end

RSpec.describe Post do
  before(:all) do
    # On your own tests this would be done automatically by Rails
    ActiveRecord::Base.establish_connection(RSpec.configuration.database_url)

    # Schema required for the demo, ignore in your own tests
    ActiveRecord::Schema.define do
      create_table :posts, force: true do |t|
      end
    end

    # Print logs in stdout instead of an file, ignore in your own tests
    ActiveRecord::Base.logger = Logger.new($stdout)
  end

  it "create new posts" do
    Post.create!
    expect(Post.count).to eq(1)
  end
end
