require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "rspec"
  gem "wkhtmltopdf-binary"
  gem "testcontainers-core", path: "../core", require: "testcontainers"
  group :test do
    gem "webmock"
  end
end

require "rspec"
require "rspec/autorun"
require "webmock/rspec"

RSpec.configure do |config|
end

RSpec::Matchers.define :exist_file do
  match do |file_path|
    File.exist?(file_path)
  end
end

describe "Wkhtmltopdf Example" do
  let(:url) { "https://getbootstrap.com/docs/5.3/examples/sticky-footer/" }
  let(:host_tmp_dir) { "#{__dir__}/tmp" }
  let(:container_tmp_dir) { "/tmp" }
  let(:file_name) { "document.pdf" }
  let(:file_path) { "#{host_tmp_dir}/#{file_name}" }
  let(:container_file_path) { "#{container_tmp_dir}/#{file_name}" }
  # wkhtmltopdf typically expects 'wkhtmltopdf [url] [output]' as command
  let(:container) do
    Testcontainers::DockerContainer.new("surnet/alpine-wkhtmltopdf:3.17.0-0.12.6-small")
      .with_entrypoint("wkhtmltopdf")
      .with_command([url, container_file_path])
  end

  before do
    FileUtils.mkdir_p(host_tmp_dir)
    WebMock.allow_net_connect!
    container.with_filesystem_binds(["#{host_tmp_dir}:#{container_tmp_dir}:rw"])
    stub_request(:get, url).to_return(
      body: File.read("#{__dir__}/fixtures/web_page/index.html")
    )
  end

  after(:each) do
    WebMock.allow_net_connect!
    if container.running?
      puts "Container logs: #{container.logs}"
      container.stop
    end
    container&.remove
    FileUtils.rm_f(file_path)
  end

  context "when using html" do
    it "generates a PDF page" do
      container.start
      # Wait with a timeout and check periodically
      10.times do |i|
        break if File.exist?(file_path)
        puts "Waiting for PDF (attempt #{i + 1}/10)..."
        sleep 1
      end

      puts "Checking for file at: #{file_path}"
      puts "File exists? #{File.exist?(file_path)}"
      puts "Directory contents: #{Dir.entries(host_tmp_dir)}"

      expect(file_path).to exist_file
    end
  end
end
