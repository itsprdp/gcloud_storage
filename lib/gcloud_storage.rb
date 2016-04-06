require "gcloud_storage/version"
require "gcloud_storage/base"
require "gcloud_storage/uploader"

module GcloudStorage
  class << self
    attr_accessor :configuration
  end

  def self.configure(options)
    self.configuration ||= GcloudStorage::Base.new(options)
  end

  def self.service
    if self.configuration
      self.configuration
    else
      raise Exception.new("Missing credentials. Please configure using GcloudStorage.configure({}).")
    end
  end
end

