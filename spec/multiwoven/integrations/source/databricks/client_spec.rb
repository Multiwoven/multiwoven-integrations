# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::Databricks::Client do
  let(:client) { Multiwoven::Integrations::Source::Databricks::Client.new }

  let(:sync_config) do
    {
      "source": {
        "name": "databrick-source",
        "type": "source",
        "connection_specification": {
          "host": "test-host.databricks.com",
          "http_path": "test_http_path",
          "access_token": "test_toekn",
          "port": "443"
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
        "name": "ExampleModel",
        "query": "SELECT * FROM CALL_CENTER",
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
        "method": "GET"
      },
      "sync_mode": "full_refresh",
      "cursor_field": "timestamp",
      "destination_sync_mode": "upsert"
    }
  end
  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow(Sequel).to receive(:odbc).and_return(true)

        result = client.check_connection(sync_config[:source][:connection_specification])
        expect(result.type).to eq("connection_status")

        connection_status = result.connection_status
        expect(connection_status.status).to eq("succeeded")
        expect(connection_status.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(Sequel).to receive(:odbc).and_raise(Sequel::DatabaseConnectionError, "Connection failed")

        result = client.check_connection(sync_config[:source][:connection_specification])
        expect(result.type).to eq("connection_status")

        connection_status = result.connection_status
        expect(connection_status.status).to eq("failed")
        expect(connection_status.message).to eq("Connection failed")
      end
    end
  end
end
