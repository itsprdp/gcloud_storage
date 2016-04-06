# GcloudStorage

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
Your ActiveRecord model file looks like this.

```ruby
class TempFile < ActiveRecord::Base
  # attribute :file
  include GcloudStorage::Uploader

  mount_gcloud_uploader :file
end
```

And create an initializer at `config/initializers/gcloud_storage.rb` and add these
lines:

```ruby
# To support large file uploads
Faraday.default_adapter = :httpclient

unless Rails.env.test?
  GcloudStorage.configure({
    # Storage bucket name
    bucket_name: AppConfig.gcs['bucket_name'],
    # Google Cloud Project ID
    project_id: AppConfig.gcs['project_id'],
    # Compute Service account json file
    key_file: Rails.root.join(AppConfig.gcs['key_file_path'])
  })
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/itsprdp/gcloud_storage. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
