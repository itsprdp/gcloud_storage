require "google/cloud/storage"
require "gcloud_storage/configuration"
require "gcloud_storage/error"
require "gcloud_storage/local_store"

module GcloudStorage
  class Base
    attr_reader :connection

    def initialize(options)
      @connection = { credentials: options }

      Error.missing_credentials unless options.is_a?(Hash)

      unless options[:storage] == :local_store
        missing_options = []

        [:bucket_name, :project_id, :key_file].each do |option|
          option_value = options[option]

          unless options[:compute_instance] && option == :key_file
            missing_options << option if (option_value.nil? || !(option_value))
          end
        end

        unless missing_options.empty?
          raise Error::Argument.new(":#{missing_options.join(', ')} are missing")
        end
      end

      # Cache service, storage and bucket to @connection
      self.bucket
    end

    def service
      storage_type = @connection[:credentials][:storage].present? ?
                        @connection[:credentials][:storage] : (:gcloud)

      begin
        @connection[:service] ||=
          if storage_type == :local_store
            LocalStore.new
          else
            Google::Cloud::Storage.new(
              project_id: @connection[:credentials][:project_id],
              credentials: @connection[:credentials][:key_file]
            )
          end
      rescue => e
        raise e
      end
    end

    def storage
      @connection[:storage] ||= (
        begin
          tries ||= 3
          self.service
        rescue => e
          retry unless (tries -= 1).zero?
          raise e
        end
      )
    end

    def bucket
      @connection[:bucket] ||= self.storage.bucket(
        @connection[:credentials][:bucket_name]
      )
    end

    def expirable_url(file_path, num_secs=300)
      file = self.bucket.file(file_path)
      file.signed_url(method: 'GET', expires: num_secs)
    end

    def upload_file(file, dest_file_path)
      remote_file = nil
      file_path = (file.respond_to?(:tempfile))? file.tempfile : file

      begin
        retries ||= 2
        remote_file = self.bucket.upload_file file_path, dest_file_path
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

        remote_file
      end
    end

    def delete_file(file_path)
      begin
        file = self.bucket.file(file_path)
        file.delete
      rescue => e
        if e.class == NoMethodError
          raise Google::Cloud::Error.new(
            "Not Found: The object you specified doesn't exist!"
          )
        else
          raise e
        end
      end
    end
  end # Base

end # GcloudStorage
