# frozen_string_literal: true

require "test_helper"
require "selenium-webdriver"

class SeleniumContainerTest < TestcontainersTest
  def before_all
    super
    @container = Testcontainers::SeleniumContainer.new
    @container.start
    @host = @container.host
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
    assert_equal "selenium/standalone-firefox:latest", @container.image
  end

  def test_it_supports_custom_capabilities_to_build_image
    container = Testcontainers::SeleniumContainer.new(capabilities: :chrome)
    assert_equal "selenium/standalone-chrome:latest", container.image
  end

  def test_it_supports_custom_image
    container = Testcontainers::SeleniumContainer.new("selenium/standalone-chrome:114.0.5735.106-chromedriver-114.0.5735.90-20230607")
    assert_equal "selenium/standalone-chrome:114.0.5735.106-chromedriver-114.0.5735.90-20230607", container.image
  end

  def test_it_returns_the_default_port
    assert_equal 4444, @container.port
  end

  def test_it_returns_the_default_port_vnc
    assert_equal 5900, @container.vnc_port
  end

  def test_it_is_configured_with_the_default_environment_variables
    assert "localhost", @container.get_env("no_proxy")
    assert "true", @container.get_env("START_XVFB")
    assert "localhost", @container.get_env("HUB_ENV_no_proxy")
  end

  def test_it_has_the_default_port_mapped_vnc
    assert @container.mapped_port(5900)
  end

  def test_it_has_the_default_port_mapped
    assert @container.mapped_port(4444)
  end

  def test_it_supports_custom_keyword_arguments
    @container = Testcontainers::SeleniumContainer.new(filesystem_binds: ["/dev/shm:/dev/shm:rw"])
    assert_equal ["/dev/shm:/dev/shm:rw"], @container.filesystem_binds
  end

  def test_it_returns_the_default_selenium_url
    assert "http://#{@host}:#{@port}/wd/hub", @container.selenium_url
  end

  def test_it_return_selenium_url_with_costume_protocol
    assert_equal "https://#{@host}:#{@port}/wd/hub", @container.selenium_url(protocol: "https://")
  end

  def test_it_is_reachable_using_firefox
    driver = Selenium::WebDriver.for(:firefox, url: @container.selenium_url)
    driver.navigate.to "https://www.google.com"

    assert driver.find_element(class: "gNO89b")
  end

  def test_it_is_reachable_using_chrome
    container = Testcontainers::SeleniumContainer.new(capabilities: :chrome)
    container.start
    driver = Selenium::WebDriver.for(:chrome, url: container.selenium_url)
    driver.navigate.to "https://www.google.com"

    assert driver.find_element(class: "gNO89b")
  end
end
