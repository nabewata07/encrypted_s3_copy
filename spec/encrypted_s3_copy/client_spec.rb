# require 'simplecov'
require_relative '../../lib/encrypted_s3_copy/client'

describe EncryptedS3Copy::Client do
  let(:bucket_name) { 'test_bkt' }
  let(:source_s3_suffix) { 'path/to/source_file_name' }
  let(:local_source_path) { '/path/to/source_file_name' }
  let(:remote_source_path) { "s3://#{bucket_name}/#{source_s3_suffix}" }
  let(:remote_dest_path) { "s3://#{bucket_name}/#{dest_s3_suffix}" }
  let(:dest_s3_suffix) { 'path/to/dest_file_name' }
  let(:local_dest_path) { '/path/to/dest_file_name' }
  let(:obj_double) { double('double of s3 object') }
  describe '#before' do

    context 'when key file path option is set' do
      let(:opt_double) { double('double of OptionParser') }
      before :each do
        allow(OptionParser).to receive(:new).and_return(opt_double)
        allow(opt_double).to receive(:on)
        allow(opt_double).to receive(:parse)
      end
      it 'should set key file path argument to instance variable' do
        key_double = double('double of encoded_key')
        decoded_key_double = double('double of decoded_key')
        expect(File).to receive(:read).with('/path/to/key').
          and_return(key_double)
        expect(key_double).to receive(:chomp).and_return(decoded_key_double)
        expect(Base64).to receive(:decode64).with(decoded_key_double).
          and_return('decoded_key_string')
        expect(opt_double).to receive(:on).
          with('-k', '--key-file=KEY_FILE_PATH').and_yield('/path/to/key')
        allow(AWS).to receive(:config).
          with(s3_encryption_key: 'decoded_key_string')
        subject.before
      end
      it 'should be given argument of source file path' do
        expect(opt_double).to receive(:on).with('-s', '--source=SOURCE_PATH')
        subject.before
      end
      it 'should set source file path to instance variable' do
        allow(opt_double).to receive(:on).with('-s', '--source=SOURCE_PATH').
          and_yield('source_file_path')
        subject.before
        path = subject.instance_variable_get(:@source)
        expect(path).to eq('source_file_path')
      end
      it 'should be given argument of destination file path' do
        expect(opt_double).to receive(:on).with('-d', '--dest=DEST_PATH')
        subject.before
      end
      it 'should set destination file path to instance variable' do
        allow(opt_double).to receive(:on).with('-d', '--dest=DEST_PATH').
          and_yield('dest_file_path')
        subject.before
        path = subject.instance_variable_get(:@dest)
        expect(path).to eq('dest_file_path')
      end
      it 'should prepare parsing option of recursive' do
        expect(opt_double).to receive(:on).with('-r', '--recursive')
        subject.before
      end
      context 'when recursive option is set' do
        it 'should set recursive option true' do
          allow(opt_double).to receive(:on).with('-r', '--recursive').
            and_yield(true)
          subject.before
          r_flag = subject.instance_variable_get(:@is_recursive)
          expect(r_flag).to be true
        end
      end
    end
  end

  describe '#handle' do
    let(:file_double) { double('double of File object') }

    before :each do
      allow(FileUtils).to receive(:mkdir_p)
    end

    context 'when recursive option is set' do

      before :each do
        subject.instance_variable_set(:@is_recursive, true)
      end

      context 'copy local files to S3' do
        it 'should call single_upload multiple times' do
          files_dirs = [
            '/source/dir/file01.txt',
            '/source/dir/file02.txt',
            '/source/dir/dir2',
            '/source/dir/dir2/file01.txt'
          ]
          subject.instance_variable_set(:@source, '/source/dir')
          subject.instance_variable_set(:@dest, 's3://dest/dir')
          allow(Dir).to receive(:glob).with('/source/dir/**/*').
            and_return(files_dirs)
          allow(File).to receive(:directory?)
          expect(File).to receive(:directory?).with('/source/dir/dir2').
            and_return(true)
          expect(subject).to receive(:single_upload).with('dest', 'dir/file01.txt')
          expect(subject).to receive(:single_upload).with('dest', 'dir/file02.txt')
          expect(subject).to receive(:single_upload).
            with('dest', 'dir/dir2/file01.txt')
          subject.send(:handle)
        end
      end

      context 'copy S3 files to local' do
        it 'should call single_download multiple times' do
          s3_objects_double = double("double of S3 objects")
          s3_dir01_double = double("double of <AWS::S3::S3Object:dest/dir/>")
          s3_file01_double = double("double of <AWS::S3::S3Object:dest/dir/sample.txt>")
          s3_file02_double = double("double of <AWS::S3::S3Object:dest/dir/test>")
          s3_dir02_double = double("double of <AWS::S3::S3Object:dest/dir/test/>")
          s3_file03_double = double("double of <AWS::S3::S3Object:dest/dir/test/myfile>")
          s3_file04_double = double("double of <AWS::S3::S3Object:dest/hoge.txt>")
          source_objs = [
            s3_dir01_double, s3_dir02_double, s3_file01_double, s3_file02_double,
            s3_file03_double, s3_file04_double
          ]
          subject.instance_variable_set(:@source, 's3://dest/dir')
          subject.instance_variable_set(:@dest, '/source/dir')

          allow(s3_dir01_double).to receive(:key).and_return('dir/')
          allow(s3_dir02_double).to receive(:key).and_return('dir/test/')
          allow(s3_file01_double).to receive(:key).and_return('dir/sample.txt')
          allow(s3_file02_double).to receive(:key).and_return('dir/test')
          allow(s3_file03_double).to receive(:key).and_return('dir/test/myfile')
          allow(s3_file04_double).to receive(:key).and_return('hoge.txt')

          allow(s3_dir01_double).to receive(:content_length).and_return(0)
          allow(s3_dir02_double).to receive(:content_length).and_return(0)
          allow(s3_file01_double).to receive(:content_length).and_return(10)
          allow(s3_file02_double).to receive(:content_length).and_return(10)
          allow(s3_file03_double).to receive(:content_length).and_return(10)
          allow(s3_file04_double).to receive(:content_length).and_return(10)

          allow(subject).to receive(:get_s3_objects).with('dest').
            and_return(s3_objects_double)

          chunk_double = double('double of chunk of s3 obj')
          expect(s3_dir01_double).not_to receive(:read)
          expect(s3_dir02_double).not_to receive(:read)
          expect(s3_file01_double).to receive(:read).and_yield(chunk_double)
          expect(s3_file02_double).to receive(:read).and_yield(chunk_double)
          expect(s3_file03_double).to receive(:read).and_yield(chunk_double)
          expect(s3_file04_double).to receive(:read).and_yield(chunk_double)

          expect(s3_objects_double).to receive(:with_prefix).with('dir/').
            and_return(source_objs)

          file_double = double('double of file object')
          allow(File).to receive(:open).and_yield(file_double)

          expect(file_double).to receive(:write).with(chunk_double).exactly(4).times

          subject.send(:handle)
        end
      end
    end

    context 'when copy single local file to s3' do
      before :each do
        subject.instance_variable_set(:@source, local_source_path)
        subject.instance_variable_set(:@dest, remote_dest_path)

        allow(obj_double).to receive(:write)
        allow(File).to receive(:open).with(local_source_path).and_return(file_double)
        allow(file_double).to receive(:close)
        allow(subject).to receive(:get_s3_object).and_return(obj_double)
      end
      it 'should get bucket object' do
        expect(subject).to receive(:get_s3_object).with(bucket_name, dest_s3_suffix)
        subject.send(:handle)
      end
      context 'when destination path is directory path' do
        let(:remote_dest_path) { "s3://#{bucket_name}/#{dest_s3_suffix}" }
        let(:dest_s3_suffix) { 'path/to/dest_dir/' }

        before :each do
          subject.instance_variable_set(:@dest, remote_dest_path)
        end
        it 'should complement file name' do
          expected_dest = dest_s3_suffix + 'source_file_name'
          expect(subject).to receive(:get_s3_object).with(bucket_name, expected_dest)
          subject.send(:handle)
        end
      end
      it 'should open source file' do
        expect(File).to receive(:open).with(local_source_path)
        subject.send(:handle)
      end
      it 'should write file contents to s3 object' do
        expect(obj_double).to receive(:write).with(file_double)
        subject.send(:handle)
      end
      it 'should close file pointer' do
        expect(file_double).to receive(:close)
        subject.send(:handle)
      end
    end

    context 'when copy single s3 file to local' do
      before :each do
        subject.instance_variable_set(:@source, remote_source_path)
        subject.instance_variable_set(:@dest, local_dest_path)
        allow(File).to receive(:open)
        allow(subject).to receive(:get_s3_object).and_return(obj_double)
      end
      it 'should execute single_download' do
        expect(subject).to receive(:single_download)
        subject.send(:handle)
      end
      it 'should get bucket' do
        expect(subject).to receive(:get_s3_object)
        subject.send(:handle)
      end
      context 'when destination path is full path' do
        it 'should open local destination file' do
          expect(File).to receive(:open).with(local_dest_path, 'wb')
          subject.send(:handle)
        end
      end
      context 'when destination path is directory path' do
        let(:local_dest_path) { '/path/to/dest/file_name/' }
        it 'should complement file name' do
          expected_dest = local_dest_path + 'source_file_name'
          expect(File).to receive(:open).with(expected_dest, 'wb')
          subject.send(:handle)
        end
      end
      it 'should read s3 object' do
        allow(File).to receive(:open).and_yield(file_double)
        expect(obj_double).to receive(:read)
        subject.send(:handle)
      end
      it 'should write contents of s3 object to local file' do
        allow(File).to receive(:open).and_yield(file_double)
        allow(obj_double).to receive(:read).and_yield('chunk')
        expect(file_double).to receive(:write).with('chunk')
        subject.send(:handle)
      end
    end

    context 'when local to local' do
      it 'should raise RuntimeError' do
        subject.instance_variable_set(:@source, local_source_path)
        subject.instance_variable_set(:@dest, local_dest_path)
        message = 'either source path or destination path or both are wrong'
        expect{ subject.send(:handle) }.to raise_error(RuntimeError, message)
      end
    end
  end

  describe 'get_s3_object' do
    let(:s3_double) { double('double of s3 client') }
    before :each do
      allow(AWS::S3).to receive(:new).and_return(s3_double)
      allow(s3_double).
        to receive_message_chain(:buckets, :[], :objects, :[]) { obj_double }
    end
    it 'should create s3 client' do
      expect(AWS::S3).to receive(:new)
      subject.send(:get_s3_object, bucket_name, dest_s3_suffix)
    end
    it 'should get s3 obj' do
      buckets_double = double('double of s3 buckets').as_null_object
      bucket_double = double('double of s3 bucket').as_null_object
      objects_double = double('double of s3 objects').as_null_object
      expect(s3_double).to receive(:buckets).and_return(buckets_double)
      expect(buckets_double).to receive(:[]).with(bucket_name).and_return(bucket_double)
      expect(bucket_double).to receive(:objects).and_return(objects_double)
      expect(objects_double).to receive(:[]).with(dest_s3_suffix)

      subject.send(:get_s3_object, bucket_name, dest_s3_suffix)
    end
  end

  describe '#execute' do
    it 'should call handle before and handle' do
      expect(subject).to receive(:before).ordered
      expect(subject).to receive(:handle).ordered
      subject.execute
    end
  end
end
