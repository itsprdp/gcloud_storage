require 'spec_helper'
require 'open-uri'

describe "GcloudStorage::Base for GcloudStorage::LocalStore" do
  before do
    GcloudStorage.configuration = nil
    GcloudStorage.connection = nil

    GcloudStorage.configure do |storage_config|
      storage_config.credentials = {
        storage: :local_store
      }
    end

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
    it "shoud return the connection hash with keys :credentials, :service, :storage and :bucket" do
      expect(GcloudStorage.service.class).to eq(GcloudStorage::Base)
      expect(GcloudStorage.service.connection.class).to eq(Hash)
      expect(GcloudStorage.service.connection.keys).to eq([:credentials, :service, :storage, :bucket])
    end

    it "should cache the GcloudStorage::LocalStore#service object" do
      expect(GcloudStorage.service.connection[:service].class).to eq(GcloudStorage::LocalStore)
    end

    it "should cache the GcloudStorage::LocalStore#storage object" do
      expect(GcloudStorage.service.connection[:storage].class).to eq(GcloudStorage::LocalStore)
    end

    it "should cache the GcloudStorage::LocalStore#bucket object" do
      expect(GcloudStorage.service.connection[:bucket].class).to eq(GcloudStorage::LocalStore)
    end
  end

  context :gcloud do
    before do
      @local_store = GcloudStorage::LocalStore.new
    end

    context :service do
      it "should return a GcloudStorage::LocalStore object" do
        expect(@local_store.service.class).to eq(GcloudStorage::LocalStore)
      end

      it "should create a new GcloudStorage::LocalStore object only if it's not cached" do
        cached_object_id = @local_store.service.object_id
        expect(@local_store.service.object_id).to eq(cached_object_id)
      end
    end

    context :storage do
      it "should return a GcloudStorage::LocalStore object" do
        expect(@local_store.storage.class).to eq(GcloudStorage::LocalStore)
      end

      it "should create a new GcloudStorage::LocalStore object only if it's not cached" do
        cached_object_id = @local_store.storage.object_id
        expect(@local_store.storage.object_id).to eq(cached_object_id)
      end
    end

    context :bucket do
      it "should return a GcloudStorage::LocalStore object" do
        expect(@local_store.bucket.class).to eq(GcloudStorage::LocalStore)
      end

      it "should create a new GcloudStorage::LocalStore object only if it's not cached" do
        cached_object_id = @local_store.bucket.object_id
        expect(@local_store.bucket.object_id).to eq(cached_object_id)
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
        expect(remote_file.members).to eq([:path, :md5])
      end

      it "should upload the file with exact contents" do
        local_file_md5 = file_md5(@local_file_path)
        remote_file = GcloudStorage.service.upload_file(@local_file_path, @remote_file_path)
        expect(remote_file.md5).to eq(local_file_md5)
      end
    end

    context :expirable_url do
      it "should return the file_path" do
        remote_url = GcloudStorage.service.expirable_url("uploads/rspec/test_file.txt")
        expect(open(remote_url).read).to eq("File created by RSpec!")
      end
    end

    context :delete_file do
      before do
        GcloudStorage.service.upload_file(@local_file_path, @remote_file_path)
      end

      it "should delete the specified file from the bucket" do
        GcloudStorage.service.delete_file(@remote_file_path)
        expect(File.exist?(@remote_file_path)).to eq(false)
      end
    end
  end
end
