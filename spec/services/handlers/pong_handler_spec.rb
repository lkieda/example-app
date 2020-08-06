RSpec.describe Handlers::PongHandler do
  let(:config_provider) { instance_double(Configuration::Provider) }
  let(:ping_handler) { described_class.new(config_provider: config_provider) }
  let(:mock_params) { Struct.new(:payload) }
  let(:params_batch) { [mock_params.new('counter' => 0)] }

  subject { ping_handler.handle(params_batch) }

  context 'when config is unavailable' do
    before { allow(config_provider).to receive(:provide) { nil } }

    it 'raises error' do
      expect { subject }.to raise_error(Errors::MissingConfigurationError)
    end
  end

  context 'when basic config is available' do
    before { allow(config_provider).to receive(:provide) { {} } }

    it 'increments counter' do
      expect(subject).to eq({'counter' => 1})
    end
  end

  context 'when config requires mood to be included' do
    before { allow(config_provider).to receive(:provide) { {'include_mood' => true} } }

    it 'increments counter' do
      expect(subject).to eq({'counter' => 1, 'mood' => ':)'})
    end
  end
end