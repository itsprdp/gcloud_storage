require 'bundler/setup'
Bundler.setup

require 'yaml'
require 'fileutils'
require 'gcloud_storage'

unless File.exist?('config.yml')
  raise Exception.new('test-bucket-service.json file is missing')
end

# Load secrets
CREDENTIALS = YAML.load_file('config.yml')["gcloud"]

# Test Module
TestGcloudStorage = GcloudStorage.dup

# Create tmp directory
FileUtils.mkdir_p 'tmp'

RSpec.configure do |config|
  GcloudStorage.configure do |storage_config|
    storage_config.credentials = {
      project_id: CREDENTIALS["project_id"],
      bucket_name: CREDENTIALS["bucket_name"],
      key_file: CREDENTIALS["key_file"]
    }
  end

  # Init connection
  GcloudStorage.initialize_service!
end
