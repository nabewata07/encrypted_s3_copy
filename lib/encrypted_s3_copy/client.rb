require 'aws-sdk'
require 'json'
require 'optparse'
require 'base64'
require 'fileutils'

module EncryptedS3Copy
class Client
  # s3://(a_bucket)/(path/to/target_file)
  S3_PATH = /^s3:\/\/([^\/]+)\/(.+)/

  def initialize(opts={})
    @source = opts[:source_path]
    @dest = opts[:destination_path]
    set_s3_encryption_key(opts[:key_file_path]) if opts[:key_file_path]
  end

  def before
    opt = OptionParser.new
    opt.on('-k', '--key-file=KEY_FILE_PATH') do |path|
      set_s3_encryption_key(path)
    end
    opt.on('-s', '--source=SOURCE_PATH') do |path|
      @source = path
    end
    opt.on('-d', '--dest=DEST_PATH') do |path|
      @dest = path
    end
    opt.on('-r', '--recursive') do |is_recursive|
      @is_recursive = is_recursive
    end
    opt.parse(ARGV)
  end

  def execute
    before
    handle
  end

  def handle
    if !(@source =~ S3_PATH) && @dest =~ S3_PATH
      if @is_recursive
        recursive_upload($1, $2)
      else
        single_upload($1, $2)
      end
    elsif !(@dest =~ S3_PATH) && @source =~ S3_PATH
      if @is_recursive
        recursive_download($1, $2)
      else
        obj = get_s3_object($1, $2)
        single_download(obj)
      end
    else
      raise 'either source path or destination path or both are wrong'
    end
  end

  private

  def set_s3_encryption_key(path)
    encoded_key = File.read(path)
    AWS.config(s3_encryption_key: Base64.decode64(encoded_key.chomp))
  end

  def recursive_download(bucket_name, suffix)
    suffix += '/' unless suffix =~ /\/$/

    s3_objects = get_s3_objects(bucket_name)
    s3_objects.with_prefix(suffix).each do |obj|
      next if obj.content_length < 1
      single_download(obj)
    end
  end

  def recursive_upload(bucket_name, suffix)
    wildcard = '**/*'
    source_dir = (@source[-1] == '/') ? @source : @source + '/'
    suffix += '/' if suffix[-1] != '/'
    files_dirs = Dir.glob(source_dir + wildcard)

    files_dirs.each do |path|
      next if File.directory?(path)
      @source = path
      input_dir_size = source_dir.size
      additional_path = path[input_dir_size..-1]

      single_upload(bucket_name, suffix + additional_path)
    end
  end

  def get_s3_object(bucket_name, suffix)
    s3 = AWS::S3.new
    s3.buckets[bucket_name].objects[suffix]
  end

  def get_s3_objects(bucket_name)
    s3 = AWS::S3.new
    s3.buckets[bucket_name].objects
  end

  def single_upload(bucket_name, suffix)
    suffix += File.basename(@source) if suffix =~ /\/$/

    s3_obj = get_s3_object(bucket_name, suffix)
    fp = File.open(@source)
    s3_obj.write(fp)
    fp.close
  end

  def single_download(s3_obj)
    dest_path = get_dest_path(s3_obj)
    FileUtils.mkdir_p(File.dirname(dest_path))
    File.open(dest_path, 'wb') do |file|
      s3_obj.read do |chunk|
        file.write(chunk)
      end
    end
  end

  def get_dest_path(s3_obj)
    unless @is_recursive
      return @dest + File.basename(@source) if @dest =~ /\/$/
      @dest
    else
      @dest += '/' unless @dest =~ /\/$/
      @source += '/' unless @source =~ /\/$/

      source_prefix = @source.gsub(/s3:\/\/([^\/])+\//, '')
      key = s3_obj.key
      diff = key[source_prefix.size..key.length]
      return @dest + diff
    end
  end
end
end

if $0 == __FILE__
  client = EncryptedS3Copy::Client.new
  client.execute
end
