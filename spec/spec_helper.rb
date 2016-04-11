require 'bundler/setup'
Bundler.setup

require 'yaml'
require 'fileutils'
require 'gcloud_storage'
require 'active_record'
require 'sqlite3'

unless File.exist?('config.yml')
  raise Exception.new('test-bucket-service.json file is missing')
end

# Load secrets
CREDENTIALS = YAML.load_file('config.yml')["gcloud"]

# Test Module
TestGcloudStorage = GcloudStorage.dup

# Create tmp directory
FileUtils.mkdir_p 'tmp'

# Open ActiveRecord connection
ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => 'gcloud_storage.db'
)

# TempFile Migration class
class CreateTempFileTable < ActiveRecord::Migration
  def up
    create_table :temp_files do |t|
      t.string :file
      t.string :alt_file
    end
  end

  def down
    drop_table :temp_files
  end
end

# Drop all old records
if ActiveRecord::Base.connection.table_exists?(:temp_files)
  CreateTempFileTable.migrate(:down)
end

# Create temp_files table
CreateTempFileTable.migrate(:up)

# Temp ActiveRecord Model clas to test mountable methods
class TempFile < ActiveRecord::Base
  include GcloudStorage::Uploader

  mount_gcloud_uploader :file, presence: true
  mount_gcloud_uploader :alt_file
end

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
