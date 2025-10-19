# frozen_string_literal: true

require "java-properties"
require_relative "version"

module Testcontainers
  module DockerClient
    module_function

    def connection
      configure
      Docker.connection
    end

    def configure
      configure_from_properties unless current_connection
      configure_user_agent
    end

    def current_connection
      Docker.instance_variable_get(:@connection)
    end

    def configure_from_properties
      properties = load_properties
      tc_host = ENV["TESTCONTAINERS_HOST"] || properties[:"tc.host"]
      Docker.url = tc_host if tc_host && !tc_host.empty?
    end

    def load_properties
      path = properties_path
      return {} unless File.exist?(path)

      JavaProperties.load(path)
    end

    def configure_user_agent
      Docker.options ||= {}
      Docker.options[:headers] ||= {}
      Docker.options[:headers]["User-Agent"] ||= "tc-ruby/#{Testcontainers::VERSION}"
    end

    def properties_path
      File.expand_path("~/.testcontainers.properties")
    end

    private_class_method :configure_from_properties, :configure_user_agent, :properties_path, :load_properties
  end
end
