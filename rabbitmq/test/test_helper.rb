$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "testcontainers/rabbitmq"

require "minitest/autorun"
require "minitest/hooks/test"
require "bunny"

class TestcontainersTest < Minitest::Test
  include Minitest::Hooks
end
