# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Klaviyo::Client do # rubocop:disable Metrics/BlockLength
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  describe "#check_connection" do
    let(:api_key) { "test_api_key" }
    let(:connection_config) { { private_api_key: api_key } }
    let(:klaviyo_endpoint) { Multiwoven::Integrations::Destination::Klaviyo::Client::KLAVIYO_AUTH_ENDPOINT }
    let(:klaviyo_payload) { Multiwoven::Integrations::Destination::Klaviyo::Client::KLAVIYO_AUTH_PAYLOAD }

    let(:headers) do
      {
        "Accept" => "application/json",
        "Authorization" => "Klaviyo-API-Key #{api_key}",
        "Revision" => "2023-02-22",
        "Content-Type" => "application/json"
      }
    end

    before do
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
    end

    context "when the connection is successful" do
      let(:response_body) { { "message" => "success" }.to_json }
      before do
        response = Net::HTTPSuccess.new("1.1", "201", "Unauthorized")
        response.content_type = "application/json"
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(klaviyo_endpoint, "POST", payload: klaviyo_payload, headers: headers).and_return(response)
      end

      it "returns a successful connection status" do
        message = subject.check_connection(connection_config)
        result = message.connection_status

        expect(result.status).to eq(Multiwoven::Integrations::Protocol::ConnectionStatusType["succeeded"])
      end
    end

    context "when the connection fails" do
      let(:error_message) { "Invalid API Key" }
      let(:response_body) { { "message" => error_message }.to_json }
      before do
        response = Net::HTTPUnauthorized.new("1.1", "401", "Unauthorized")
        response.content_type = "application/json"
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(klaviyo_endpoint, "POST", payload: klaviyo_payload, headers: headers).and_return(response)
      end

      it "returns a failed connection status with an error message" do
        message = subject.check_connection(connection_config)
        result = message.connection_status

        expect(result.status).to eq(Multiwoven::Integrations::Protocol::ConnectionStatusType["failed"])
        expect(result.message).to eq(error_message)
      end
    end

    context "when the response body is not JSON" do
      let(:error_message) { "Klaviyo auth failed" }
      before do
        response = Net::HTTPUnauthorized.new("1.1", "401", "Unauthorized")
        response.content_type = "application/json"
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(klaviyo_endpoint, "POST", payload: klaviyo_payload, headers: headers).and_return(response)
      end

      it "returns a failed connection status with a default error message" do
        message = subject.check_connection(connection_config)
        result = message.connection_status

        expect(result.status).to eq(Multiwoven::Integrations::Protocol::ConnectionStatusType["failed"])
        expect(result.message).to include("Klaviyo auth failed")
      end
    end
  end

  describe "#write" do
    let(:sync_config_json) do
      {
        "source": {
          "name": "SourceConnectorName",
          "type": "source",
          "connection_specification": {
            "private_api_key": "test"
          }
        },
        "destination": {
          "name": "DestinationConnectorName",
          "type": "destination",
          "connection_specification": {
            "private_api_key": "test"
          }
        },
        "model": {
          "name": "ExampleModel",
          "query": "SELECT * FROM CALL_CENTER LIMIT 1",
          "query_type": "raw_sql",
          "primary_key": "id"
        },
        "stream": {
          "name": "example_stream", "action": "create",
          "json_schema": { "field1": "type1" },
          "supported_sync_modes": %w[full_refresh incremental],
          "source_defined_cursor": true,
          "default_cursor_field": ["field1"],
          "source_defined_primary_key": [["field1"], ["field2"]],
          "namespace": "exampleNamespace",
          "url": "https://api.example.com/data",
          "request_method": "POST"
        },
        "sync_mode": "full_refresh",
        "cursor_field": "timestamp",
        "destination_sync_mode": "upsert"
      }
    end

    let(:records) do
      [{ data: { id: 1, name: "Sample Record 1" }, emitted_at: Time.now.to_i },
       { data: { id: 2, name: "Sample Record 2" }, emitted_at: Time.now.to_i }]
    end

    context "when the write is successful" do
      it "increments the success count" do
        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(
          sync_config_json.to_json
        )

        stub_request(:any, sync_config.stream.url)
          .to_return(status: 200, body: '{"message": "Success"}')
        tracker = subject.write(sync_config, records)

        expect(tracker[:success]).to eq(records.count)
        expect(tracker[:failed]).to eq(0)
      end
    end

    context "when the write operation fails" do
      it "increments the failure count" do
        sync_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(
          sync_config_json.to_json
        )
        stub_request(:any, sync_config.stream.url)
          .to_return(status: 500, body: '{"message": "Error"}')

        tracker = subject.write(sync_config, records)

        expect(tracker[:failed]).to eq(records.count)
        expect(tracker[:success]).to eq(0)
      end
    end
  end
end
