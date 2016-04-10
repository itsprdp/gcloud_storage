require "spec_helper"
require "byebug"

describe GcloudStorage::Uploader do
  context :included do
    it "should respond to ClassMethods methods" do
      expect(TempFile.respond_to?(:mount_gcloud_uploader)).to eq(true)
    end
  end

  context :ClassMethods do
    context :mount_gcloud_uploader do

      context :public_methods do
        [
          :file_uploader_object, :file_uploader_object=,
          :file_path, :file_url, :file_expirable_url
        ].each do |msg|
          it "should respond to #{msg}" do
            byebug if msg == :upload_file_to_gc
            expect(TempFile.new.respond_to?(msg)).to eq(true)
          end
        end

      end

      context :private_methods do
        [
          :file_presence, :upload_file_to_gc, :delete_file_from_gc,
          :upload_file_file_to_gc, :delete_file_file_from_gc, :expirable_gc_url,
          :init_file_name_for_file, :sanitize_filename, :return_filename
        ].each do |msg|
          it "should respond to #{msg}" do
            expect(TempFile.new.respond_to?(msg, true)).to eq(true)
          end
        end

      end

      context :upload_file do
        before do

        end
      end

    end
  end

end
