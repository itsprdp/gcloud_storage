# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gcloud_storage/version'

Gem::Specification.new do |spec|
  spec.name          = "gcloud_storage"
  spec.version       = GcloudStorage::VERSION
  spec.authors       = ["Pradeep G"]
  spec.email         = ["itsprdp@gmail.com"]

  spec.summary       = %q{Simple Google Cloud Storage file upload gem for Ruby.}
  spec.description   = %q{Simple Google Cloud Storage file upload gem for Ruby. You can use this as an alternative to carrierwave with fog.}
  spec.homepage      = "https://github.com/itsprdp/google-cloud-storage"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency             "gcloud", "0.7.2"
  spec.add_dependency             "faraday", "0.9.0"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "sqlite3"
end
