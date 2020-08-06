# frozen_string_literal: true

RSpec.describe InlineBatchConsumer do
  subject(:consumer) { karafka_consumer_for(:inline_batch_data) }

  let(:nr1_value) { rand }
  let(:nr2_value) { rand }
  let(:sum) { nr1_value + nr2_value }

  before do
    publish_for_karafka({ 'number' => nr1_value }.to_json)
    publish_for_karafka({ 'number' => nr2_value }.to_json)
    allow(Karafka.logger).to receive(:info)
  end

  it 'expects to log a proper message' do
    consumer.consume
    expect(Karafka.logger).to have_received(:info).with("Sum of 2 elements equals to: #{sum}")
  end
end
