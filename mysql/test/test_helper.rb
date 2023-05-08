$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "testcontainers/mysql"

require "minitest/autorun"
require "minitest/hooks/test"
require "mysql2"

class TestcontainersTest < Minitest::Test
  include Minitest::Hooks
end
