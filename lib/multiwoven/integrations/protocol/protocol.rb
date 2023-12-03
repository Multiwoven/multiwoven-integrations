# frozen_string_literal: true

module Multiwoven
  module Integrations::Protocol
    module Types
      include Dry.Types()
    end

    SyncMode = Types::String.enum("full_refresh", "incremental")
    SyncStatus = Types::String.enum("started", "running", "complete", "incomplete")
    DestinationSyncMode = Types::String.enum("append", "overwrite", "append_dedup")

    class ProtocolModel < Dry::Struct
      class << self
        def from_json(json_string)
          data = JSON.parse(json_string)
          new(keys_to_symbols(data))
        end

        # TODO: move to core utils
        def keys_to_symbols(hash)
          if hash.is_a?(Hash)
            hash.each_with_object({}) do |(key, value), result|
              result[key.to_sym] = keys_to_symbols(value)
            end
          elsif hash.is_a?(Array)
            hash.map { |item| keys_to_symbols(item) }
          else
            hash
          end
        end
      end
    end

    class ConnectionStatus < ProtocolModel
      attribute :status, Types::String.enum("succeeded", "failed")
      attribute :message, Types::String.optional
    end

    class ConnectorSpecification < ProtocolModel
      attribute? :documentationUrl, Types::String.optional
      attribute? :changelogUrl, Types::String.optional
      attribute :connectionSpecification, Types::Hash
      attribute :supportsNormalization, Types::Bool.default(false)
      attribute :supportsDBT, Types::Bool.default(false)
      attribute? :supported_destination_sync_modes, Types::Array.of(DestinationSyncMode).optional
    end

    class LogMessage < ProtocolModel
      attribute :level, Types::String.enum("fatal", "error", "warn", "info", "debug", "trace")
      attribute :message, Types::String
      attribute? :stack_trace, Types::String.optional
    end

    class RecordMessage < ProtocolModel
      attribute :stream, Types::String
      attribute :data, Types::Hash
      attribute :emitted_at, Types::Integer
    end

    class Stream < ProtocolModel
      attribute :name, Types::String
      attribute :json_schema, Types::Hash
      attribute :supported_sync_modes, Types::Array.of(SyncMode)
      attribute? :source_defined_cursor, Types::Bool.optional
      attribute? :default_cursor_field, Types::Array.of(Types::String).optional
      attribute? :source_defined_primary_key, Types::Array.of(Types::Array.of(Types::String)).optional
      attribute? :namespace, Types::String.optional
    end

    class Catalog < ProtocolModel
      attribute :streams, Types::Array.of(Stream)
    end

    class SyncConfig < ProtocolModel
      attribute :stream, Stream
      attribute :sync_mode, SyncMode
      attribute? :cursor_field, Types::Array.of(Types::String).optional
      attribute :destination_sync_mode, DestinationSyncMode
      attribute? :primary_key, Types::Array.of(Types::Array.of(Types::String)).optional
    end
  end
end
