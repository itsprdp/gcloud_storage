require "spec_helper"
require "open-uri"

describe GcloudStorage::Uploader do
  before do
    GcloudStorage.configuration = nil
    GcloudStorage.connection = nil

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

  describe :included do
    it "should respond to ClassMethods methods" do
      expect(TempFile.respond_to?(:mount_gcloud_uploader)).to eq(true)
    end
  end

  describe :ClassMethods do
    describe :mount_gcloud_uploader do

      describe :public_methods do
        [
          :file_uploader_object, :file_uploader_object=,
          :file_path, :file_url, :file_expirable_url
        ].each do |msg|
          it "should respond to #{msg}" do
            expect(TempFile.new.respond_to?(msg)).to eq(true)
          end
        end

      end

      describe :private_methods do
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
          local_file_path = "tmp/test.txt"
          File.open(local_file_path, "w") { |file| file.write("File created by RSpec!") }
          @temp_file = TempFile.new(file_uploader_object: local_file_path )
          @temp_file_persisted = TempFile.create(file_uploader_object: local_file_path )
        end

        it "is invalid to have the empty file_uploader_object when the presence validation is enabled" do
          temp_file = TempFile.new
          expect(temp_file.valid?).to eq(false)
          expect(temp_file.errors[:file].include?("cannot be empty. Please set a file path for :file_uploader_object attribute.")).to eq(true)
        end

        describe :file_path do
          it "should return the non-persisted file_path if the object is not persisted" do
            expect(@temp_file.file_path).to eq("uploads/temp_files/non_persisted/files/test.txt")
          end

          it "should return the file_path with the object id" do
            expect(@temp_file_persisted.file_path).to eq("uploads/temp_files/#{@temp_file_persisted.id}/files/test.txt")
          end
        end

        describe :file_url do
          it "should return the public url to the file" do
            url = @temp_file_persisted.file_url
            expect(url.include?("https://storage.googleapis.com")).to eq(true)
            expect(url.include?("files/test.txt")).to eq(true)
            expect(open(url).read).to eq("File created by RSpec!")
          end

          it "should return nil for non-persisted records" do
            expect(@temp_file.file_url).to eq(nil)
          end
        end

        describe :file_exists? do
          it "should return true if file exists" do
            expect(@temp_file.file_exists?).to be_truthy
          end

          it "should return false if file is not found" do
            allow(@temp_file).to receive(:file_url).and_raise(Gcloud::Storage::ApiError.new("Not Found", 404, []))
            expect(@temp_file.file_exists?).to be_falsey
          end

          it "should raise errors other then ApiError" do
            allow(@temp_file).to receive(:file_url).and_raise("DummyError")
            expect{@temp_file.file_exists?}.to raise_error
          end
        end

        describe :file_expirable_url do
          it "should return the public url of the file with the specified expiration" do
            url = @temp_file_persisted.file_expirable_url(10)
            expect(url.include?("https://storage.googleapis.com")).to eq(true)
            expect(url.include?("files/test.txt")).to eq(true)
            expect(open(url).read).to eq("File created by RSpec!")
          end

          it "should return nil for non-persisted records" do
            expect(@temp_file.file_expirable_url(10)).to eq(nil)
          end
        end

        it "should initialize the file attribute with the file name and extension" do
          expect(@temp_file.file).to eq("test.txt")
        end
      end

    end
  end

end
