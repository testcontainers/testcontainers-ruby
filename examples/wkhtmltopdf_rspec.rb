require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'rspec'
  gem 'wkhtmltopdf-binary'
  gem 'testcontainers-core', path: '../core', require: 'testcontainers'
end

require 'rspec'
require 'rspec/autorun'

RSpec.configure do |config|
end

describe 'Wkhtmltopdf Example' do
  let(:url) { 'https://google.com' }
  let(:pdfs_path) { "#{__dir__}/pdfs:/pdfs:rw" }
  let(:command) { [url, file_name] }
  let(:file_name) { '/pdfs/google.pdf' }
  let(:container) do
    Testcontainers::DockerContainer.new('surnet/alpine-wkhtmltopdf:3.17.0-0.12.6-small')
  end
  let(:file_path) { __dir__ + file_name }

  before do
    container.with_filesystem_binds([pdfs_path])
             .with_command(command)
             .start
  end

  after do
    container&.stop
    container&.remove
  end

  it 'generates a PDF page from URL' do
    expect(File).to exist(file_path)
  end
end
