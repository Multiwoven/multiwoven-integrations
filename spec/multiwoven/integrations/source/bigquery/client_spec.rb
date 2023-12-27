# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::Bigquery::Client do
  let(:client) { Multiwoven::Integrations::Source::Bigquery::Client.new }
  let(:sync_config) do
    {
      "source": {
        "name": "BigQuerySourceConnector",
        "type": "source",
        "connection_specification": {
          "project_id": "project",
          "dataset_id": "profile",
          "credentials_json": "sample_json"
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
        "name": "ExampleBigQueryModel",
        "query": "SELECT * FROM profile.customer LIMIT 10;",
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
  let(:bigquery_instance) { instance_double(Google::Cloud::Bigquery::Project) }
  let(:bigquery_dataset) { instance_double(Google::Cloud::Bigquery::Dataset) }
  let(:bigquery_table) { instance_double(Google::Cloud::Bigquery::Table) }
  let(:bigquery_schema) { instance_double(Google::Cloud::Bigquery::Schema) }
  let(:bigquery_field) { instance_double(Google::Cloud::Bigquery::Schema::Field) }

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow(Google::Cloud::Bigquery).to receive(:new).and_return(bigquery_instance)
        allow(bigquery_instance).to receive(:datasets).and_return([])
        result = client.check_connection(sync_config[:source][:connection_specification].with_indifferent_access)
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(Google::Cloud::Bigquery).to receive(:new).and_raise(PG::Error.new("Connection failed"))
        result = client.check_connection(sync_config[:source][:connection_specification].with_indifferent_access)
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  describe "#discover" do
    it "discovers schema successfully" do
      allow(Google::Cloud::Bigquery).to receive(:new).and_return(bigquery_instance)
      allow(bigquery_instance).to receive(:datasets).and_return([bigquery_dataset])
      allow(bigquery_dataset).to receive(:dataset_id).and_return("profile")
      allow(bigquery_dataset).to receive(:tables).and_return([bigquery_table])
      allow(bigquery_table).to receive(:table_id).and_return("customer")
      allow(bigquery_table).to receive(:schema).and_return(bigquery_schema)
      allow(bigquery_schema).to receive(:fields).and_return([bigquery_field])
      allow(bigquery_field).to receive(:name).and_return("FullName")
      allow(bigquery_field).to receive(:type).and_return("string")
      allow(bigquery_field).to receive(:mode).and_return("NULLABLE")

      streams = client.discover(sync_config[:source][:connection_specification].with_indifferent_access)

      expect(streams).to be_an(Array)
      first_stream = streams.first
      expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
      expect(first_stream.name).to eq("customer")
      expect(first_stream.json_schema).to be_an(Hash)
      expect(first_stream.json_schema["type"]).to eq("object")
      expect(first_stream.json_schema["properties"]).to eq({ "FullName" => { "type" => "string" } })
    end
  end
end
