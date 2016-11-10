# GcloudStorage [![Gem Version](https://badge.fury.io/rb/gcloud_storage.svg)](https://badge.fury.io/rb/gcloud_storage) [![Build Status](https://travis-ci.org/itsprdp/gcloud_storage.svg?branch=master)](https://travis-ci.org/itsprdp/gcloud_storage) [![Coverage Status](https://coveralls.io/repos/github/itsprdp/gcloud_storage/badge.svg?branch=compute_instances)](https://coveralls.io/github/itsprdp/gcloud_storage?branch=compute_instances)

Simple Google Cloud Storage file upload gem for Ruby. This is an alternative gem
for carrierwave with fog. As, carrierwave with fog only uses API Key
authentication to talk to Google Cloud Storage API. This gem supports the
service account authentication and as well as compute instance service account
where you don't have to initialize the gem with the credentials.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gcloud_storage'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gcloud_storage

## Usage

Model:
```ruby
class TempFile < ActiveRecord::Base
  include GcloudStorage::Uploader

  # attribute :file
  mount_gcloud_uploader :file #[, presence: true] #=> Run's presence validation
end
```

Migration:
```ruby
class CreateTempFiles < ActiveRecord::Migration
  def change
    create_table :temp_files do |t|
      t.string :file

      t.timestamps null: false
    end
  end
end
```

Attachment Methods:
```ruby
temp_file = TempFile.new(file_uploader_object: path_to_file) # => TempFile object
temp_file.file_exists? # => false
temp_file.save
temp_file.file_exists? # => true
temp_file.file_url # => HTTPS URL which expires in 300 seconds bye default
temp_file.file_expirable_url(60) # => HTTPS URL which expires in 60 seconds
temp_file.file_path # => "/uploads/#{model_name}s/:id/#{attribute_name}s/filename.extension"
```

Create an initializer file `config/initializers/gcloud_storage.rb` and add these
lines:

For remote storage:
```ruby
# Uncomment this to support large file uploads
# Faraday.default_adapter = :httpclient

GcloudStorage.configure do |config|
  config.credentials = {
    bucket_name: 'bucket_name', # Storage bucket name
    project_id: 'project_id',   # Google Cloud Project ID
    key_file: 'key_file_path'   # Compute Service account json file
  }
end

# Add this to validate and cache connection object
# while loading the Rails Application
# GcloudStorage.initialize_service!
```

For local storage:
```ruby
GcloudStorage.configure do |config|
  config.credentials = {
    storage: :local_store
  }
end

# Add this to validate and cache connection object
# while loading the Rails Application
# GcloudStorage.initialize_service!
```

File upload example:
You can pass path to the file to be uploaded as a `String` or as `Pathname` or
as `Rack::Multipart::UploadedFile` object using HTML Multipart form.
The attribute to initialize will be `#{column}_uploader_object`. Here the column
name is file in the above example.

```
$ rails console
Loading development environment (Rails 4.2.0)
 :001 > `echo "This is a test file" > temp.txt`
 => ""
 :002 > file = Rack::Multipart::UploadedFile.new("temp.txt")
 => #<Rack::Multipart::UploadedFile:0x007f9e29ae37c8 @content_type="text/plain", @original_filename="temp.txt", @tempfile=#<Tempfile:/var/folders/temp.txt>>
 :003 > temp_file = TempFile.new(file_uploader_object: file) # file_attribute => #{column}_uploader_object
 => #<TempFile id: nil, file: "temp.txt", created_at: nil, updated_at: nil>
 :004 > temp_file.valid?
 => true
 :005 > temp_file.save
 => true
 :006 > temp_file.file_url
 => "https://storage.googleapis.com/<bucket-name>/uploads/temp_files/1/files/temp.txt?GoogleAccessId=compute%40developer.gserviceaccount.com&Expires=1459851006&Signature=XXXX"
 :007 > `echo "Yet Another test file" > tmp/yet_another_test.txt`
 => ""
 :008 > another_file = TempFile.new(file_uploader_object: "tmp/yet_another_test.txt")
 => #<TempFile id: nil, file: "yet_another_test.txt", created_at: nil, updated_at: nil>
 :009 > another_file.save
 => true
 :010 > another_file.file_url
 => "https://storage.googleapis.com/<bucket-name>/uploads/temp_files/2/files/yet_another_test.txt?GoogleAccessId=compute%40developer.gserviceaccount.com&Expires=1459851800&Signature=XXXX"
 :011 > open(another_file.file_url).read
 => "Yet Another test file\n"
 :012 > another_file.file_path
 => "uploads/temp_files/2/files/yet_another_test.txt"
```

## TODO
1. More specs for GcloudStorage::Uploader
2. Support overriding the mountable methods in a better way. For now the user
   can override the methods in the model.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
run specs locally you need to setup a service account on google cloud project
and add the service json file to the root directory as
`test-bucket-service.json` and create `config.yml` from `config.yml.example`
and fill in the appropriate values.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/itsprdp/gcloud_storage. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
