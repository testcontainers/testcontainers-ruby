require_relative "selenium/version"
require "testcontainers"

module Testcontainers
  # SeleniumContainer class is used to manage containers that runs a automaticates test

  class SeleniumContainer < ::Testcontainers::DockerContainer
    # Default ports used by the container
    SELENIUM_DEFAULT_PORT = 4444
    VNC_DEFAULT_PORT = 5900
    SE_VNC_PASSWORD = 1

    # Hash that contains the images for the build of the containers of selenium that runs in the browsers chrome and firefox
    SELENIUM_IMAGES = {
      firefox: "selenium/standalone-firefox:latest",
      chrome: "selenium/standalone-chrome:latest"
    }

    attr_reader :headless

    # Initializes a new instance of SeleniumContainer
    # @param image [String]  is use to define the image for the container
    # @param capabilities [Symbol] is use to define the image that are vailable for browser between firefox and chrome
    # @param port [String] is use to define the connection port for the container for Selenium
    # @param kwargs [Hash] the options to pass to the container. See {DockerContainer#initialize}
    def initialize(image = nil, capabilities: :firefox, headless: false, vnc_no_password: nil, vnc_password: nil, **kwargs)
      image = image || SELENIUM_IMAGES[capabilities]
      super(image, **kwargs)
      @vnc_password = vnc_password
      @vnc_no_password = vnc_no_password
      @headless = headless
      @wait_for ||= add_wait_for(:logs, /Started Selenium/)
    end

    # Starts the container
    # @return [SeleniumContainer] self
    def start
      with_exposed_ports([port, vnc_port])
      _configure
      super
    end

    # Returns the port used by the container
    # @return [Integer] the port used by the container
    def port
      SELENIUM_DEFAULT_PORT
    end

    # @return [Integer] the port used by the container of vnc
   def vnc_port
     VNC_DEFAULT_PORT
   end

   # @
   def selenium_url(protocol: "http://")
     "#{protocol}#{host}:#{mapped_port(port)}/wd/hub"
   end

   private 

   def _configure
     if @vnc_no_passsword
       add_env("SE_VNC_NO_PASSWORD", "1")
     end

     if @vnc_password
       add_env("SE_VNC_PASSWORD", @vnc_password)
     end 

     add_env("START_XVFB", "#{!@headless}")
     add_env("no_proxy", "localhost")
     add_env("HUB_ENV_no_proxy","localhost")
  end
  end
end
