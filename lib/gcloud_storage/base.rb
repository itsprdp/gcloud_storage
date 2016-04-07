require "gcloud"

module GcloudStorage
  class Base
    attr_reader :connection

    def initialize
      @connection, missing_options = {}, []

      [:bucket_name, :project_id, :key_file].each do |option|
        option_value = GcloudStorage.configuration.credentials[option]
        missing_options << option if (option_value.nil? || option_value.empty?)
      end

      unless missing_options.empty?
        raise ArgumentError.new(":#{missing_options.join(',')} are missing")
      end

      # Cache service, storage and bucket to @connection
      self.bucket

      # Return cached connection hash
      @connection
    end

    def service
      begin
        @connection[:service] ||= Gcloud.new(
          GcloudStorage.configuration.credentials[:project_id],
          GcloudStorage.configuration.credentials[:key_file]
        )
      rescue => e
        raise e
      end
    end

    def storage
      @connection[:storage] ||= (
        begin
          tries ||= 3
          self.service.storage
        rescue => e
          retry unless (tries -= 1).zero?
          raise e
        end
      )
    end

    def bucket
      @connection[:bucket] ||= self.storage.bucket(
        GcloudStorage.configuration.credentials[:bucket_name]
      )
    end

    #TODO Move these methods to file class
    def expirable_url(file_path, num_secs=300)
      file = self.bucket.file(file_path)
      file.signed_url(method: 'GET', expires: num_secs)
    end

    #TODO Move these methods to file class
    def upload_file(file, dest_file_path)
      remote_file = nil
      file_path = (file.respond_to?(:tempfile))? file.tempfile : file

      begin
        retries ||= 2
        remote_file = bucket.upload_file file_path, dest_file_path
      rescue => e
        unless (retries -= 1).zero?
          retry
        else
          raise e
        end
      else
        unless remote_file.md5 == Digest::MD5.base64digest(File.read(file_path))
          raise Exception.new('Uploaded file is corrupted.')
        end
      end
    end

    #TODO Move these methods to file class
    def delete_file(file_path)
      begin
        file = bucket.file(file_path)
        file.delete
      rescue => e
        raise e
      end
    end
  end # Base

end # GcloudStorage
