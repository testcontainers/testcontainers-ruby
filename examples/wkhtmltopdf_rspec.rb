require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'rspec'
  gem 'wkhtmltopdf-binary'
  gem 'testcontainers-core', path: '../core', require: 'testcontainers'

  group :test do
    gem 'webmock'
  end
end

require 'rspec'
require 'rspec/autorun'
require 'webmock/rspec'

RSpec.configure do |config|
end

RSpec::Matchers.define :exist_file do
  match do |file_path|
    File.exist?(file_path)
  end
end

describe 'Wkhtmltopdf Example' do
  let(:url) { 'https://getbootstrap.com/docs/5.3/examples/sticky-footer/' }
  let(:pdfs_path) { "#{__dir__}/pdfs:/pdfs:rw" }
  let(:command) { [url, file_name] }
  let(:file_name) { '/pdfs/document.pdf' }
  let(:file_path) { "#{__dir__}#{file_name}" }
  let(:container) do
    Testcontainers::DockerContainer.new('surnet/alpine-wkhtmltopdf:3.17.0-0.12.6-small')
  end

  before do
    WebMock.allow_net_connect!
    container.with_filesystem_binds([pdfs_path])
  end

  after(:each) do
    WebMock.allow_net_connect!
    container&.stop
    container&.remove
  end

  context 'when using html' do
    before(:each) do
      stub_request(:get, url).to_return(
        body: File.read("#{__dir__}/fixtures/web_page/index.html")
      )
    end

    it 'generates a PDF page' do
      container.with_command(command)
      container.start

      expect(file_path).to exist_file
    end
  end
end
