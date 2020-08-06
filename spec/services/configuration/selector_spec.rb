# frozen_string_literal: true

RSpec.describe Configuration::Selector do
  subject { selector.select(configuration_by_time, at_time: time) }

  let(:selector) { described_class.new(time_format: time_format) }
  let(:time) { Time.parse('2020-08-03 12:00:00 UTC') }
  let(:time_format) { '%H:%M:%S' }

  context 'when no configuration is present' do
    let(:configuration_by_time) { {} }

    it { is_expected.to be_nil }
  end

  context 'when only future configuration is present' do
    let(:configuration_by_time) { { '12:00:01' => { config: 'future' } } }

    it { is_expected.to be_nil }
  end

  context 'when multiple configs found' do
    context 'when tested time falls on configuration start time' do
      let(:configuration_by_time) do
        {
          '11:59:59' => { config: 'past' },
          '12:00:00' => { config: 'right now' },
          '12:00:01' => { config: 'future' }
        }
      end

      it { is_expected.to eq({ config: 'right now' }) }
    end

    context 'when tested time falls between configuration start times' do
      let(:configuration_by_time) do
        {
          '11:59:58' => { config: 'too early in the past' },
          '11:59:59' => { config: 'most recent' },
          '12:00:01' => { config: 'future' },
          '12:00:02' => { config: 'far future' }
        }
      end

      it { is_expected.to eq({ config: 'most recent' }) }
    end
  end
end
