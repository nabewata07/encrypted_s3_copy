# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'encrypted_s3_copy/version'

Gem::Specification.new do |spec|
  spec.name          = "encrypted_s3_copy"
  spec.version       = EncryptedS3Copy::VERSION
  spec.authors       = ["nabewata07"]
  spec.email         = ["channel.momo@gmail.com"]
  spec.summary       = %q{upload and download encrypted files to/from AWS S3}
  spec.description   = %q{upload and download encrypted files to/from AWS S3}
  spec.homepage      = "https://github.com/nabewata07/encrypted_s3_copy"
  spec.license       = "MIT"

  spec.required_ruby_version = '>= 2.0'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 2.99"
end
