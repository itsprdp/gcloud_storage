require 'spec_helper'

describe GcloudStorage do
  [
    :configuration, :connection,
    :configure, :service,
    :initialize_service!
  ].each do |msg|
    it "should respond to #{msg}" do
      expect(GcloudStorage).to respond_to(msg)
    end
  end

  context :configuration do
    before do
      TestGcloudStorage.configure do |config|
        config.credentials = {
          bucket_name: "bucket_name",
          project_id: "project_id",
          key_file: "key_file_path"
        }
      end
    end

    it "should return GcloudStorage::Configuration object" do
      expect(TestGcloudStorage.configuration.class).to eq(TestGcloudStorage::Configuration)
    end

    it "should not create a new GcloudStorage::Configuration object if it's already created" do
      cached_object_id = TestGcloudStorage.configuration.object_id
      4.times { expect(TestGcloudStorage.configuration.object_id).to eq(cached_object_id) }
    end

    context :credentials do
      it "should have the values specified in the configure block" do
        credentials = TestGcloudStorage.configuration.credentials
        expect(credentials[:bucket_name]).to eq("bucket_name")
        expect(credentials[:project_id]).to eq("project_id")
        expect(credentials[:key_file]).to eq("key_file_path")
      end
    end

  end

  context :service do
    it "should return GcloudStorage::Base object" do
      expect(GcloudStorage.connection.class).to eq(GcloudStorage::Base)
    end

    it "should not create a new GcloudStorage::Base object if it's already created" do
      cached_object_id = GcloudStorage.connection.object_id
      4.times { expect(GcloudStorage.connection.object_id).to eq(cached_object_id) }
    end
  end

  context :initialize_service! do
    it "should return GcloudStorage::Base object" do
      expect(GcloudStorage.connection.class).to eq(GcloudStorage::Base)
    end

    it "should not create a new GcloudStorage::Base object if it's already created" do
      cached_object_id = GcloudStorage.connection.object_id
      4.times { expect(GcloudStorage.connection.object_id).to eq(cached_object_id) }
    end

    it "should raise an error if the configuration returns nil" do
      TestGcloudStorage.configuration = nil

      expect { TestGcloudStorage.initialize_service! }.to raise_error(GcloudStorage::ConfigurationError, /Please configure/)
    end
  end
end
