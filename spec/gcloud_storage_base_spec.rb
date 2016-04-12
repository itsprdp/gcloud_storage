require 'spec_helper'
require 'open-uri'

describe "GcloudStorage::Base for Gcloud" do
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

  [
    :storage, :bucket, :service,
    :expirable_url, :upload_file, :delete_file
  ].each do |msg|
    it "should respond to #{msg}" do
      expect(GcloudStorage.connection).to respond_to(msg)
    end
  end

  def file_md5(file_path)
    Digest::MD5.base64digest(File.read(file_path))
  end

  context :initialization do
    context :validation_errors do
      it "should have the GcloudStorage::Configuration object to initialize" do
        expect { GcloudStorage::Base.new(nil) }.to raise_error(
          GcloudStorage::Error::Configuration,/Please configure/
        )
      end

      it "should have the valid credentials to initialize" do
        expect { GcloudStorage::Base.new({}) }.to raise_error(
          GcloudStorage::Error::Argument,/bucket_name, project_id, key_file are missing/
        )
      end
    end

    it "shoud return the connection hash with keys :credentials, :service, :storage and :bucket" do
      expect(GcloudStorage.service.class).to eq(GcloudStorage::Base)
      expect(GcloudStorage.service.connection.class).to eq(Hash)
      expect(GcloudStorage.service.connection.keys).to eq([:credentials, :service, :storage, :bucket])
    end

    it "should cache the Gcloud#service object" do
      expect(GcloudStorage.service.connection[:service].class).to eq(Object)
    end

    it "should cache the Gcloud#storage object" do
      expect(GcloudStorage.service.connection[:storage].class).to eq(Gcloud::Storage::Project)
    end

    it "should cache the Gcloud#bucket object" do
      expect(GcloudStorage.service.connection[:bucket].class).to eq(Gcloud::Storage::Bucket)
    end
  end

  context :gcloud do
    before do
      @gcloud = GcloudStorage::Base.new(GcloudStorage.configuration.credentials)
    end

    context :service do
      it "should return a Gcloud object" do
        expect(@gcloud.service.class).to eq(Object)
      end

      it "should create a new Gcloud object only if it's not cached" do
        cached_object_id = @gcloud.service.object_id
        expect(@gcloud.service.object_id).to eq(cached_object_id)
      end
    end

    context :storage do
      it "should return a Gcloud::Storage::Project object" do
        expect(@gcloud.storage.class).to eq(Gcloud::Storage::Project)
      end

      it "should create a new Gcloud::Storage::Project object only if it's not cached" do
        cached_object_id = @gcloud.storage.object_id
        expect(@gcloud.storage.object_id).to eq(cached_object_id)
      end
    end

    context :bucket do
      it "should return a Gcloud::Storage::Bucket object" do
        expect(@gcloud.bucket.class).to eq(Gcloud::Storage::Bucket)
      end

      it "should create a new Gcloud::Storage::Bucket object only if it's not cached" do
        cached_object_id = @gcloud.bucket.object_id
        expect(@gcloud.bucket.object_id).to eq(cached_object_id)
      end
    end
  end

  context :file_methods do
    before do
      @local_file_path = "tmp/test_file.txt"
      @remote_file_path = "uploads/rspec/test_file.txt"
      @file_content = "File created by RSpec!"

      File.open(@local_file_path, "w") { |file| file.write(@file_content) }
    end

    context :upload_file do
      it "should upload the file to the Gcloud#storage bucket" do
        remote_file = GcloudStorage.service.upload_file(@local_file_path, @remote_file_path)
        expect(remote_file.class).to eq(Gcloud::Storage::File)
      end

      it "should upload the file with exact contents" do
        local_file_md5 = file_md5(@local_file_path)
        remote_file = GcloudStorage.service.upload_file(@local_file_path, @remote_file_path)
        expect(remote_file.md5).to eq(local_file_md5)

        # verify the file
        remote_file.download("tmp/remote_test_file.txt")
        expect(file_md5("tmp/remote_test_file.txt")).to eq(local_file_md5)
      end
    end

    context :expirable_url do
      it "should return the expirable public url with the validity of 300 seconds" do
        remote_url = GcloudStorage.service.expirable_url("uploads/rspec/test_file.txt")
        expect(open(remote_url).read).to eq("File created by RSpec!")
      end

      it "should expire after 10 seconds" do
        remote_url = GcloudStorage.service.expirable_url("uploads/rspec/test_file.txt",10)
        expect(open(remote_url).read).to eq("File created by RSpec!")
        sleep(10)
        expect { open(remote_url).read }.to raise_error(OpenURI::HTTPError, /400 Bad Request/)
      end
    end

    context :delete_file do
      before do
        GcloudStorage.service.upload_file(@local_file_path, @remote_file_path)
      end

      it "should delete the specified file from the bucket" do
        status = GcloudStorage.service.delete_file(@remote_file_path)
        expect(status).to eq(true)
        expect { GcloudStorage.service.delete_file(@remote_file_path) }.to raise_error(Gcloud::Storage::ApiError,/Not Found/)
      end
    end
  end
end
