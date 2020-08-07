# frozen_string_literal: true

RSpec.describe Configuration::StoreRepository do
  let(:connection) { instance_spy(Redis) }
  let(:logger) { spy }
  let(:store_manager) { described_class.new(connection: connection, logger: logger) }

  describe '#configuration_by_start_time' do
    subject { store_manager.configuration_by_start_time }

    context 'when no keys are present' do
      before { allow(connection).to receive(:keys).and_return([]) }

      it { is_expected.to eq({}) }
    end

    context 'when keys and values are present' do
      let(:keys) { %w[1 2] }
      let(:values) do
        [
          { key1: 'value1' }.to_json,
          { key2: 'value2' }.to_json
        ]
      end
      let(:expected_result) do
        {
          '1' => { 'key1' => 'value1' },
          '2' => { 'key2' => 'value2' }
        }
      end

      before do
        allow(connection).to receive(:keys) { keys }
        allow(connection).to receive(:mget).with(keys) { values }
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#set_configuration' do
    subject(:set_configuration) do
      store_manager.set_configuration(configuration, time_now: time_now, propagation_buffer: propagation_buffer)
    end

    let(:configuration) { { key: 'value' } }
    let(:time_now) { Time.parse('2020-08-03 12:00:00 UTC') }
    let(:propagation_buffer) { 10.seconds }

    it do
      set_configuration

      expect(logger).to have_received(:info)
    end

    it do
      set_configuration

      expect(connection).to have_received(:set).with(time_now + propagation_buffer, configuration.to_json)
    end
  end

  describe '#remove_all_configuration' do
    subject(:remove_all_configuration) { store_manager.remove_all_configuration }

    it do
      remove_all_configuration

      expect(connection).to have_received(:flushdb)
    end
  end
end
