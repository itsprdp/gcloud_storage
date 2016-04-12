module GcloudStorage
  class Configuration
    attr_accessor :credentials

    def initialize
      @credentials = {
        project_id: "",
        bucket_name: "",
        key_file: nil,
        compute_instance: nil
      }
    end
  end
end
