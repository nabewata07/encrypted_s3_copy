# EncryptedS3Copy

Tool to upload files to AWS S3 with client-side encryption and download client-side encrypted files.

## Installation

Add this line to your application's Gemfile:

    gem 'encrypted_s3_copy'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install encrypted_s3_copy

## Usage

### generate symmetric key
command options

    -k, --key-file=KEY_FILE_PATH

For client side encryption of AWS S3, generate symmetric key and save to file.

    $ aes_key_gen -k /path/to/symmetric_key/file

### Upload or download encrypted file from/to AWS S3

command options

    -k, --key-file=KEY_FILE_PATH
    -s, --source=SOURCE_PATH
    -d, --dest=DEST_PATH
    -r, --recursive

### upload
#### single file
    $ encrypted_s3_copy -k /path/to/symmetric/key/file -s /path/to/local/file -d s3://bucket/suffix/to/file
#### recursive mode
    $ encrypted_s3_copy -k /path/to/symmetric/key/file -s /path/to/local/directory/ -d s3://bucket/suffix/to/directory/ --recursive

### download
#### single file
    $ encrypted_s3_copy -k /path/to/symmetric/key/file -s s3://bucket/suffix/to/file -d /path/to/local/file
#### recursive mode
    $ encrypted_s3_copy -k /path/to/symmetric/key/file -s s3://bucket/suffix/to/directory/ -d /path/to/local/directory/ --recursive

## Contributing

1. Fork it ( https://github.com/nabewata07/encrypted_s3_copy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
