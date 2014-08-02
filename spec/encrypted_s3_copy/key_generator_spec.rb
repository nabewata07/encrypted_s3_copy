require_relative '../../lib/encrypted_s3_copy/key_generator'

describe EncryptedS3Copy::KeyGenerator do
  describe '#parse_arg' do
    let(:optparse_double) {
      double('double of OptionParser instance').as_null_object
    }

    before :each do
      allow(OptionParser).to receive(:new).and_return(optparse_double)
      allow(OptionParser).to receive(:on)
    end

    it 'should prepare parse key file argument' do
      expect(optparse_double).to receive(:on).
        with('-k', '--key-file=KEY_FILE_PATH')

      subject.parse_arg
    end
    it 'should set key file path argument to instance variable' do
      expected_path = 'a_path'
      allow(optparse_double).to receive(:on).
        with('-k', '--key-file=KEY_FILE_PATH').and_yield(expected_path)
      subject.parse_arg

      actual = subject.instance_variable_get(:@key_file_path)
      expect(actual).to eq(expected_path)
    end
    it 'should parse args' do
      expect(optparse_double).to receive(:parse)
      subject.parse_arg
    end
  end

  describe '#generate_key' do
    let(:cipher_double) { double('double of OpenSSL::Cipher instance') }
    let(:random_key_double) { double('double of random key') }
    let(:encoded_key_double) { double('double of encoded key string') }

    before :each do
      allow(File).to receive(:write)
      allow(File).to receive(:chmod)
      allow(OpenSSL::Cipher).to receive(:new).and_return(cipher_double)
      allow(cipher_double).to receive(:random_key).and_return(random_key_double)
      allow(Base64).to receive(:encode64).and_return(encoded_key_double)
    end

    it 'should create OpenSSL::Cipher instance' do
      expect(OpenSSL::Cipher).to receive(:new).with("AES-256-ECB").
        and_return(cipher_double)
      subject.generate_key
    end
    it 'should create random key' do
      expect(cipher_double).to receive(:random_key)
      subject.generate_key
    end

    context 'after generate key' do
      before :each do
        subject.instance_variable_set(:@key_file_path, 'input_path')
      end

      it 'shuold Base64 encode random key' do
        expect(Base64).to receive(:encode64).with(random_key_double)
        subject.generate_key
      end
      it 'should write key to file' do
        expect(File).to receive(:write).with('input_path', encoded_key_double)
        subject.generate_key
      end
      it 'should set secret file permission' do
        expect(File).to receive(:chmod).with(0600, 'input_path')
        subject.generate_key
      end

    end
  end

  describe '#execute' do
    it 'should call parse_arg and generate_key method' do
      expect(subject).to receive(:parse_arg).ordered
      expect(subject).to receive(:generate_key).ordered
      subject.execute
    end
  end
end
