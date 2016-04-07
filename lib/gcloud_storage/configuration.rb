module GcloudStorage
  class Configuration
    attr_accessor :credentials

    def initialize
      @credentials = {
        project_id: "",
        bucket_name: "",
        key_file: ""
      }
    end
  end
end
