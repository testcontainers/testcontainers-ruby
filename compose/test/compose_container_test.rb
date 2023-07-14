# frozen_string_literal: true

require "test_helper"

class ComposeContainerTest < TestcontainersTest
  def before_all
    super

    @container = Testcontainers::ComposeContainer.new
    @container.start
    @host = @container.host
    binding.pry
    @port = @container.first_mapped_port
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
