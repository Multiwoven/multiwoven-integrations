# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module Databricks
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
      rescue Sequel::DatabaseConnectionError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification
        connection_config = connection_config.with_indifferent_access
        query = sync_config.model.query
        query = batched_query(query, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?

        db = create_connection(connection_config)

        query(db, query)
      rescue StandardError => e
        handle_exception(
          "DATABRICKS:READ:EXCEPTION",
          "error",
          e
        )
      end

      private

      def query(connection, query)
        records = []
        connection.fetch(query) do |row|
          records << RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
        records
      end

      def create_connection(connection_config)
        Sequel.odbc(drvconnect: generate_drvconnect(connection_config))
      end

      def generate_drvconnect(connection_config)
        "Driver=#{DATABRICKS_DRIVER_PATH};
        Host=#{connection_config[:host]};
        PORT=#{connection_config[:port]};
        SSL=1;
        HTTPPath=#{connection_config[:http_path]};
        PWD=#{connection_config[:access_token]};
        UID=token;
        ThriftTransport=2;AuthMech=3;
        AllowSelfSignedServerCert=1;
        CAIssuedCertNamesMismatch=1"
      end
    end
  end
end
