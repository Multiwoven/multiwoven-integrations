# frozen_string_literal: true

module Multiwoven
  module Integrations::Protocol
    RSpec.describe ConnectionStatus do
      describe ".from_json" do
        it "creates an instance from JSON" do
          json_data = '{"status": "succeeded", "message": "Connection succeeded"}'
          instance = ConnectionStatus.from_json(json_data)
          expect(instance).to be_a(ConnectionStatus)
          expect(instance.status).to eq("succeeded")
          expect(instance.message).to eq("Connection succeeded")
        end
      end
    end

    RSpec.describe ConnectorSpecification do
      describe ".from_json" do
        it "creates an instance from JSON" do
          json_data = '{"connection_specification": {"key": "value"}, "supports_normalization": true, "supports_dbt": true, "supported_destination_sync_modes": ["append"]}'
          instance = ConnectorSpecification.from_json(json_data)
          expect(instance).to be_a(ConnectorSpecification)
          expect(instance.connection_specification).to eq(key: "value")
          expect(instance.supports_normalization).to eq(true)
          expect(instance.supports_dbt).to eq(true)
          expect(instance.supported_destination_sync_modes).to eq(["append"])
        end
      end
    end
    RSpec.describe LogMessage do
      describe ".from_json" do
        let(:json_data) do
          {
            "level" => "info",
            "message" => "Sample log message",
            "stack_trace" => "Sample stack trace"
          }.to_json
        end

        it "creates an instance from JSON" do
          log_message = described_class.from_json(json_data)

          expect(log_message).to be_a(described_class)
          expect(log_message.level).to eq("info")
          expect(log_message.message).to eq("Sample log message")
          expect(log_message.stack_trace).to eq("Sample stack trace")
        end
      end
    end

    RSpec.describe RecordMessage do
      describe ".from_json" do
        it "creates an instance from JSON" do
          json_data = '{"stream": "example_stream", "data": {"key": "value"}, "emitted_at": 1638449455000}'
          instance = RecordMessage.from_json(json_data)
          expect(instance).to be_a(RecordMessage)
          expect(instance.stream).to eq("example_stream")
          expect(instance.data).to eq(key: "value")
          expect(instance.emitted_at).to eq(1_638_449_455_000)
        end
      end
    end

    RSpec.describe Stream do
      describe ".from_json" do
        it "creates an instance from JSON" do
          json_data = '{"name": "example_stream", "json_schema": {"type": "object"}, "supported_sync_modes": ["full_refresh"]}'
          instance = Stream.from_json(json_data)
          expect(instance).to be_a(Stream)
          expect(instance.name).to eq("example_stream")
          expect(instance.json_schema).to eq(type: "object")
          expect(instance.supported_sync_modes).to eq(["full_refresh"])
        end
      end
    end

    RSpec.describe Catalog do
      describe ".from_json" do
        it "creates an instance from JSON" do
          json_data = '{"streams": [{"name": "example_stream", "json_schema": {"type": "object"}, "supported_sync_modes": ["full_refresh"]}]}'
          instance = Catalog.from_json(json_data)
          expect(instance).to be_a(Catalog)
          expect(instance.streams.first).to be_a(Stream)
          expect(instance.streams.first.name).to eq("example_stream")
        end
      end
    end

    RSpec.describe SyncConfig do
      describe ".from_json" do
        it "creates an instance from JSON" do
          json_data = '{"stream": {"name": "example_stream", "json_schema": {"type": "object"}, "supported_sync_modes": ["full_refresh"]}, "sync_mode": "full_refresh", "destination_sync_mode": "append"}'
          instance = SyncConfig.from_json(json_data)
          expect(instance).to be_a(SyncConfig)
          expect(instance.stream).to be_a(Stream)
          expect(instance.stream.name).to eq("example_stream")
          expect(instance.sync_mode).to eq("full_refresh")
          expect(instance.destination_sync_mode).to eq("append")
        end
      end
    end
  end
end
