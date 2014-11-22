require 'webmock/rspec'
require 'json'
require 'byebug'
require 'coveralls'
Coveralls::Output.silent = true
Coveralls.wear!

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.mock_with :mocha
  config.order = 'random'
end

def expect_zendesk(subdomain, endpoint)
  ENV["zendesk_user"] = "foo@bar.com"
  ENV["zendesk_token"] = "123abc"
  crazy_piece = "foo%40bar.com%2Ftoken:123abc"
  stub_request(:get, %r{#{subdomain}.zendesk.com.#{endpoint}})
end

def create_test_file!(temp_file = true)
  datafile = Tempfile.new(["standup", ".json"], File.join(`pwd`.chop, "test")) if temp_file
  datafile ||= File.join(`pwd`.chop, "test", "standup.json")
  stub_filename(datafile)
end

def stub_filename(datafile)
  path = datafile.is_a?(String) ? datafile : datafile.path
  Standupguy::DataMethods.stubs(:filename).returns(path)
  Standupguy::Report.any_instance.stubs(:filename).returns(path)
  Standupguy::Item.any_instance.stubs(:filename).returns(path)
  datafile
end

def expect_datafile(file, pattern)
  data = File.read(file.path)
  expect(data).to match(pattern)
end

def key(date=:today)
  return DateTime.now.strftime("%Y-%m-%d") if date==:today
  return DateTime.strptime(date,"%Y-%m-%d") if date.is_a?(String)
end