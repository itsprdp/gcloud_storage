module GcloudStorage
  module Error
    class Configuration < StandardError; end
    class Argument < ArgumentError; end

    def self.missing_credentials
      raise Configuration.new("Missing credentials. Please configure using GcloudStorage.configure(&block).")
    end
  end
end
