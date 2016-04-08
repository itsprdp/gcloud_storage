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
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  def self.service
    self.connection || self.initialize_service!
  end

  def self.initialize_service!
    if self.configuration
      self.connection ||= Base.new(self.configuration.credentials)
    else
      Error.missing_credentials
    end
  end
end
