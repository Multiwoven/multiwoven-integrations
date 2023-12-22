# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::Redshift::Client do
  let(:client) { Multiwoven::Integrations::Source::Redshift::Client.new }
  let(:mock_connection) { instance_double("PG::Connection") }
  # let(:fake_result) { instance_double("PG::Result") }
  before do
    allow(PG).to receive(:connect).and_return(mock_connection)
    # allow(fake_result).to receive(:each).and_yield(
    #   id: 1, name: "John"
    # ).and_yield(
    #   id: 2, name: "Jane"
    # )
    fake_result = [{id: 1, name: "John"},{id: 2, name: "Jane"}]
    allow(mock_connection).to receive(:exec).and_return(fake_result)
    
    allow(mock_connection).to receive(:close)
  end

  let(:sync_config) do
    {
      "source": {
        "name": "RedshiftSourceConnector",
        "type": "source",
        "connection_specification": {
          "credentials": {
            "auth_type": "username/password",
            "username": ENV["REDSHIFT_USERNAME"],
            "password": ENV["REDSHIFT_PASSWORD"]
          },
          "host": ENV["HOST"],
          "port": ENV["PORT"],
          "database": ENV["DATABASE"],
          "schema": ENV["SCHEMA"]
        }
      },
      "destination": {
        "name": "DestinationConnectorName",
        "type": "destination",
        "connection_specification": {
          "example_destination_key": "example_destination_value"
        }
      },
      "model": {
        "name": "ExampleRedshiftModel",
        "query": "SELECT * FROM contacts LIMIT 10;",
        "query_type": "raw_sql",
        "primary_key": "id"
      },
      "sync_mode": "full_refresh",
      "cursor_field": ["timestamp"],
      "destination_sync_mode": "upsert"
    }
  end
  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow(Sequel).to receive(:postgres).and_return(true)

        result = client.check_connection(sync_config[:source][:connection_specification])
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(PG).to receive(:connect).and_raise(PG::Error.new("Connection failed"))

        result = client.check_connection(sync_config[:source][:connection_specification])
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  # read and #discover tests for Redshift
  describe "#read" do
    context "when reading records from a real Redshift database" do
      xit "reads records successfully" do
        records = client.read(Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json))

        expect(records).to be_an(Array)
        
        expect(records).not_to be_empty
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
      end
    end
  end
end
