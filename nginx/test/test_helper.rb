$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "testcontainers/nginx"

require "minitest/autorun"
require "minitest/hooks/test"
require "net/http"

class TestcontainersTest < Minitest::Test
  include Minitest::Hooks
end
