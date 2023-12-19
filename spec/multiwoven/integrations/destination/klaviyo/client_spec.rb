# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Klaviyo::Client do
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

      let(:response_body) { {"message" => "success" }.to_json }
      before do
        response = Net::HTTPSuccess.new("1.1", "201", "Unauthorized")
        response.content_type = "application/json"
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(klaviyo_endpoint, "POST", payload: klaviyo_payload, headers: headers).and_return(response)
      end

      it "returns a successful connection status" do
        result = subject.check_connection(connection_config)
        expect(result.status).to eq(Multiwoven::Integrations::Protocol::ConnectionStatusType["succeeded"])
      end
    end

    context "when the connection fails" do
      let(:error_message) { "Invalid API Key" }
      let(:response_body) { {"message" => error_message }.to_json }
      before do
        response = Net::HTTPUnauthorized.new("1.1", "401", "Unauthorized")
        response.content_type = "application/json"
        allow(response).to receive(:body).and_return(response_body)
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(klaviyo_endpoint, "POST", payload: klaviyo_payload, headers: headers).and_return(response)
      end

      it "returns a failed connection status with an error message" do
        result = subject.check_connection(connection_config)
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
        result = subject.check_connection(connection_config)
        expect(result.status).to eq(Multiwoven::Integrations::Protocol::ConnectionStatusType["failed"])
        expect(result.message).to include("Klaviyo auth failed")
      end
    end
  end
end