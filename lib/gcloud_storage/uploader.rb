module GcloudStorage
  module Uploader
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      #TODO: Support multiple columns
      def mount_gcloud_uploader(column)
        column = column.to_s if column.is_a?(Symbol)

        attr_accessor :"#{column}_uploader_object"
        attr_accessible :"#{column}_uploader_object"

        after_save :"upload_#{column}_file_to_gc"
        before_destroy :"delete_#{column}_file_from_gc"

        after_initialize :init_file_name_for_column, if: lambda { send(:"#{column}_uploader_object").present? }

        validate :"#{column}_presence"

        define_method(:"#{column}_presence") do
          errors.add(column,'cannot be empty. Please select a file.') unless send(column.to_sym).present?
        end

        define_method(:"#{column}_file_path") do
          "uploads/#{self.class.to_s.underscore}s/#{self.id || "non_persisted"}/#{send(column.to_sym)}"
        end

        # TODO: Generic method to support multiple columns
        define_method(:"#{column}_url") do
          GcloudStorage.service.expirable_url(send(:"#{column}_file_path")) if persisted?
        end

        # TODO: Generic method to support multiple columns
        define_method(:"upload_#{column}_file_to_gc") do
          if send(:"#{column}_changed?") && send(:"#{column}_uploader_object")
            GcloudStorage.service.upload_file(send(:"#{column}_uploader_object"), send(:"#{column}_file_path"))
          end
        end

        # TODO: Generic method to support multiple columns
        define_method(:"delete_#{column}_file_from_gc") do
          GcloudStorage.service.delete_file(send(:"#{column}_file_path")) if send(column.to_sym).present?
        end

        define_method(:sanitize_filename) do |file_name|
          file_name.gsub(/[^0-9A-z.\-]/, '_')
        end

        define_method(:return_filename) do |file|
          if file.is_a?(String)
            file.split("/").last
          elsif file.is_a?(Pathname)
            file.to_s
          elsif file.is_a?(Rack::Multipart::UploadedFile)
            file.original_filename
          end
        end

        define_method(:init_file_name_for_column) do
          send(:"#{column}=", sanitize_filename(return_filename(send(:"#{column}_uploader_object")))) if send(:"#{column}_uploader_object").present?
        end
      end # mount_custom_uploader
    end # ClassMethods

  end # Uploader
end # GcloudStorage
