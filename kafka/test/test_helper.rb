$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "testcontainers/kafka"

require "minitest/autorun"
require "minitest/hooks/test"

class TestcontainersTest < Minitest::Test
  include Minitest::Hooks
end
