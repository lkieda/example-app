# frozen_string_literal: true

RSpec.describe Configuration::Provider do
  subject { provider.provide }

  let(:store_repository) { instance_double(Configuration::StoreRepository) }
  let(:provider) do
    described_class.new(store_repository: store_repository, selector: selector)
  end
  let(:selector) { instance_double(Configuration::Selector) }
  let(:time) { Time.parse('2020-08-03 12:00:00 UTC') }
  let(:configuration) { { config: 'something' } }

  before do
    allow(store_repository).to receive(:configuration_by_start_time) { configuration_by_start_time }
  end

  context 'when no configuration fetched' do
    let(:configuration_by_start_time) { {} }

    it { is_expected.to be_nil }
  end

  context 'when configuration fetched' do
    before { allow(selector).to receive(:select) { configuration } }

    let(:configuration_by_start_time) { { 'start_time' => configuration } }

    it { is_expected.to eq(configuration) }
  end
end
