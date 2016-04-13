require "fileutils"

module GcloudStorage
  class LocalStore
    def initialize
      @path = "#{FileUtils.pwd}/public/"

      FileUtils.mkdir_p(@path + "/uploads") unless Dir.exist?(@path)

      @file = Struct.new(:path, :md5) do
        def signed_url(_arg1=nil,_arg2=nil)
          path
        end

        def delete
          abs_path = "#{@path}#{path}"
          ret = FileUtils.rm(abs_path) if File.exist?(abs_path)
          abs_path == ret[0] if ret
        end
      end
    end

    def service
      self
    end

    def storage
      self
    end

    def bucket(_bucket_name=nil)
      self
    end

    def file(file_path)
      abs_file_path = "#{@path}#{file_path}"
      @file.new(abs_file_path)
    end

    def upload_file file_path, dest_path
      dest_file_path = "#{@path}#{dest_path}"
      copy_file(file_path, dest_file_path)
      @file.new(dest_file_path, file_md5(dest_file_path))
    end

    private
      def file_md5(file_path)
        Digest::MD5.base64digest(File.read(file_path))
      end

      def copy_file(src, dest)
        dest_dir = dest.split("/")
        _file_name = dest_dir.pop
        dest_dir = dest_dir.join("/")

        FileUtils.mkdir_p(dest_dir) unless Dir.exist?(dest_dir)
        FileUtils.cp(src, dest)
      end

  end
end
