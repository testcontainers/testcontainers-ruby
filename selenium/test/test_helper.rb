$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "testcontainers/selenium"

require "minitest/autorun"
require "minitest/hooks/test"
require "pry"

class TestcontainersTest < Minitest::Test
  include Minitest::Hooks
end
