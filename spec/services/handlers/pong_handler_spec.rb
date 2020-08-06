# frozen_string_literal: true

RSpec.describe Handlers::PongHandler do
  subject(:handle) { ping_handler.handle(params_batch) }

  let(:config_provider) { instance_double(Configuration::Provider) }
  let(:ping_handler) { described_class.new(config_provider: config_provider) }
  let(:mock_params) { Struct.new(:payload) }
  let(:params_batch) { [mock_params.new('counter' => 0)] }

  context 'when config is unavailable' do
    before { allow(config_provider).to receive(:provide).and_return(nil) }

    it 'raises error' do
      expect { handle }.to raise_error(Errors::MissingConfigurationError)
    end
  end

  context 'when basic config is available' do
    before { allow(config_provider).to receive(:provide).and_return({}) }

    it 'increments counter' do
      expect(handle).to eq({ 'counter' => 1 })
    end
  end

  context 'when config requires mood to be included' do
    before { allow(config_provider).to receive(:provide).and_return({ 'include_mood' => true }) }

    it 'increments counter and includes mood' do
      expect(handle).to include({ 'mood' => ':)' })
    end
  end
end
