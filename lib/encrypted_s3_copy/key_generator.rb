require 'openssl'
require 'base64'
require 'optparse'

module EncryptedS3Copy
class KeyGenerator

  def parse_arg
    opt = OptionParser.new
    opt.on('-k', '--key-file=KEY_FILE_PATH') do |path|
      @key_file_path = path
    end
    opt.parse(ARGV)
  end

  def generate_key
    my_key = OpenSSL::Cipher.new("AES-256-ECB").random_key
    encoded = Base64.encode64(my_key)

    File.write(@key_file_path, encoded)
    File.chmod(0600, @key_file_path)
  end

  def execute
    parse_arg
    generate_key
  end
end
end

if $0 == __FILE__
  generator = EncryptedS3Copy::KeyGenerator.new
  generator.execute
end
