module GcloudStorage
  module Uploader
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def mount_gcloud_uploader(column, options = {}, &block)
        private_methods = []

        attr_accessor :"#{column}_uploader_object"

        after_save :"upload_#{column}_file_to_gc", if: lambda { send(:"#{column}_changed?") }
        before_destroy :"delete_#{column}_file_from_gc"

        after_initialize :"init_file_name_for_#{column}", if: lambda { send(:"#{column}_uploader_object").present? }

        if options[:presence] == true
          validate :"#{column}_presence"

          define_method(:"#{column}_presence") do
            errors.add(column,"cannot be empty. Please set a file path for :#{column}_uploader_object attribute.") unless send(column.to_sym).present?
          end

          private_methods << :"#{column}_presence"
        end

        define_method(:"#{column}_path") do
          "uploads/#{self.class.to_s.underscore}s/#{self.id || "non_persisted"}/#{column}s/#{send(column.to_sym)}"
        end

        define_method(:"#{column}_url") do
          expirable_gc_url(send(:"#{column}_path"))
        end

        define_method(:"#{column}_expirable_url") do |num_secs|
          expirable_gc_url(send(:"#{column}_path"), num_secs)
        end

        define_method(:"upload_#{column}_file_to_gc") do
          upload_file_to_gc(send(:"#{column}_uploader_object"), send(:"#{column}_path")) if send(:"#{column}_uploader_object").present?
        end

        define_method(:"delete_#{column}_file_from_gc") do
          delete_file_from_gc(send(:"#{column}_path")) if send(column.to_sym).present?
        end

        define_method(:"init_file_name_for_#{column}") do
          send(:"#{column}=", sanitize_filename(return_filename(send(:"#{column}_uploader_object"))))
        end

        private_methods.push(
          :"upload_#{column}_file_to_gc",
          :"delete_#{column}_file_from_gc",
          :"init_file_name_for_#{column}"
        )

        unless respond_to?(:sanitize_filename)
          define_method(:sanitize_filename) do |file_name|
            file_name.gsub(/[^0-9A-z.\-]/, '_')
          end

          private_methods << :sanitize_filename
        end

        unless respond_to?(:return_filename)
          define_method(:return_filename) do |file|
            if file.is_a?(String)
              file.split("/").last
            elsif file.is_a?(Pathname)
              file.to_s
            elsif file.is_a?(Rack::Multipart::UploadedFile)
              file.original_filename
            end
          end

          private_methods << :return_filename
        end

        unless respond_to?(:upload_file_to_gc)
          define_method(:upload_file_to_gc) do |file_path, dest_path|
            GcloudStorage.service.upload_file(file_path, dest_path)
          end

          private_methods << :upload_file_to_gc
        end

        unless respond_to?(:delete_file_from_gc)
          define_method(:delete_file_from_gc) do |file_path|
            GcloudStorage.service.delete_file(file_path)
          end

          private_methods << :delete_file_from_gc
        end

        unless respond_to?(:expirable_gc_url)
          define_method(:expirable_gc_url) do |file_path, num_secs = 300|
            GcloudStorage.service.expirable_url(file_path, num_secs) if persisted?
          end

          private_methods << :expirable_gc_url
        end

        private_methods.each {|method| private method}
      end # mount_custom_uploader
    end # ClassMethods

  end # Uploader
end # GcloudStorage
