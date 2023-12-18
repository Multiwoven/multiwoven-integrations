# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Klaviyo::Client do
  describe '#check_connection' do
    let(:api_key) { 'test_api_key' }
    let(:connection_config) { { private_api_key: api_key } }
    let(:klaviyo_endpoint) { Multiwoven::Integrations::Destination::Klaviyo::Client::KLAVIYO_AUTH_ENDPOINT }
    let(:url) { "#{klaviyo_endpoint}?api_key=#{api_key}" }

    before do
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
    end

    context 'when the connection is successful' do
      before do
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(url, 'GET', headers: { 'Accept' => 'application/json' }).and_return(status: '200', body: '{}')
      end

      it 'returns a successful connection status' do
        result = subject.check_connection(connection_config)
        expect(result.status).to eq(Multiwoven::Integrations::Protocol::ConnectionStatusType["succeeded"])
      end
    end

    context 'when the connection fails' do
      let(:error_message) { 'Invalid API Key' }
      before do
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(url, 'GET', headers: { 'Accept' => 'application/json' }).and_return(status: '401', body: { 'message' => error_message }.to_json)
      end

      it 'returns a failed connection status with an error message' do
        result = subject.check_connection(connection_config)
        expect(result.status).to eq(Multiwoven::Integrations::Protocol::ConnectionStatusType["failed"])
        expect(result.message).to eq(error_message)
      end
    end

    context 'when the response body is not JSON' do
      before do
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(url, 'GET', headers: { 'Accept' => 'application/json' }).and_return(status: '500')
      end

      it 'returns a failed connection status with a default error message' do
        result = subject.check_connection(connection_config)
        expect(result.status).to eq(Multiwoven::Integrations::Protocol::ConnectionStatusType["failed"])
        expect(result.message).to eq('Klaviyo auth failed')
      end
    end
  end
end