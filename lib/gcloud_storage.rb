require "gcloud_storage/version"
require "gcloud_storage/configuration"
require "gcloud_storage/base"
require "gcloud_storage/uploader"
require "gcloud_storage/error"

module GcloudStorage
  class << self
    attr_accessor :configuration, :connection
  end

  def self.configure
    self.configuration ||= GcloudStorage::Configuration.new
    yield(configuration)
  end

  def self.service
    self.connection || self.initialize_service!
  end

  def self.initialize_service!
    if self.configuration
      self.connection ||= GcloudStorage::Base.new
    else
      raise GcloudStorage::ConfigurationError.new("Missing credentials. Please configure using GcloudStorage.configure(&block).")
    end
  end
end
