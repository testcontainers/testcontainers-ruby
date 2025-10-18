# frozen_string_literal: true

require "test_helper"

class TestcontainersTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Testcontainers::VERSION
  end

  def test_that_it_sets_user_agent_header
    assert_equal "tc-ruby/#{::Testcontainers::VERSION}", Docker.options[:headers]["User-Agent"]
  end
end
