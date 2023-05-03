# frozen_string_literal: true

class TestcontainersTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Testcontainers::VERSION
  end
end
