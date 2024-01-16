# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::FacebookCustomAudiences::Client do

  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:access_token) { "test_access_token" }
  let(:ad_account_id) { "your_ad_account_id" }
  let(:connection_config) { { access_token: access_token, ad_account_id: ad_account_id } }

  let(:facebook_audience_json_schema) do
    catalog = client.discover.catalog
    catalog.streams.find { |stream| stream.name == "audience" }.json_schema
  end

  let(:sync_config) do
    {
      destination: {
        name: "Facebook Custom Audience",
        type: "destination",
        connection_specification: connection_config
      },
      stream: {
        name: "audience",
        action: "create",
        json_schema: facebook_audience_json_schema
      },
      sync_mode: "full_refresh",
      cursor_field: "timestamp",
      destination_sync_mode: "append"
    }.with_indifferent_access
  end

  let(:records) do
    [
      build_record("8c05c9fe994ebbf6e4d7d93f1693df442e75d7541ac5efb1c796433b9fe63897", "US")
    ]
  end

  describe "#check_connection" do
    let(:success_response) { instance_double("Response", success?: true, body: "{\"data\": []}", code: 200) }
    let(:failure_response) { instance_double("Response", success?: false, body: "{\"error\": \"error_message\"}", code: 400) }

    it "returns a successful connection status if the request is successful" do
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).and_return(success_response)
      allow(client).to receive(:extract_data).with(success_response).and_return([{ "id" => "act_your_ad_account_id" }])
      message = client.check_connection(connection_config)
      result = message.connection_status
      expect(result.status).to eq(Multiwoven::Integrations::Protocol::ConnectionStatusType["succeeded"])
    end

    it "raises an error if the ad account is not found in the response" do
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).and_return(success_response)
      allow(client).to receive(:extract_data).with(success_response).and_return([{ "id" => "your_ad_account_id" }])
      message = client.check_connection(connection_config)
      result = message.connection_status
      expect(result.status).to eq(Multiwoven::Integrations::Protocol::ConnectionStatusType["failed"])
      expect(result.message).to eq( "Ad account not found in business account")
    end

    it "returns a failed connection status if the request is not successful" do
      allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).and_return(failure_response)
      message = client.check_connection(connection_config)
      result = message.connection_status
      expect(result.status).to eq(Multiwoven::Integrations::Protocol::ConnectionStatusType["failed"])
    end
  end

  describe "#discover" do
    it "returns a catalog with streams" do
      message = client.discover
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      expect(catalog.streams.first.name).to eq("audience")
      expect(catalog.streams.first.request_method).to eql("POST")
    end
  end

  def build_record(email, country)
    Multiwoven::Integrations::Protocol::RecordMessage.new(
      data: { "EMAIL": email, "COUNTRY": country },
      emitted_at: Time.now.to_i
    )
  end
end
