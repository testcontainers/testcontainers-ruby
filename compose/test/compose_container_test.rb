# frozen_string_literal: true

require "test_helper"


class ComposeContainerTest < TestcontainersTest

  TEST_PATH = Dir.getwd
  def before_all
    super

    @container = Testcontainers::ComposeContainer.new(filepath: TEST_PATH)
    @container.start
    @container.create
    @host = @container.host
    @port = @container.first_mapped_port

    
    @container.logs
    binding.pry
  end

  def after_all
    if @container&.exists?
      @container&.stop if @container&.running?
      @container&.remove
    end

    super
  end

  def test_it_returns_the_default_image
    assert_equal "docker/compose:latest", @container.image
  end

  def test_it_supports_custom_capabilities_to_build_image
    container = Testcontainers::ComposeContainer.new(image: "docker/compose")
    assert_equal "docker/compose", container.image
  end

end
