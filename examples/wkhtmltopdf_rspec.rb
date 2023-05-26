require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "minitest"
  gem "testcontainers-core", path: "../core", require: "testcontainers"
end

require "minitest"
require "minitest/autorun"

class WkhtmltopdfTest < Minitest::Test
  def setup
    @container = Testcontainers::DockerContainer.new("surnet/alpine-wkhtmltopdf:3.17.0-0.12.6-small")
      .with_filesystem_binds(["#{__dir__}/pdfs:/pdfs:rw"])
      .with_command(["https://google.com", "/pdfs/google.pdf"])
      .start
  end

  def teardown
    @container&.stop
    @container&.remove
  end

  def test_wkhtmltopdf
    assert File.file?(__dir__ + "/pdfs/google.pdf")
  end
end
