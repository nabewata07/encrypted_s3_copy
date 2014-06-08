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
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
