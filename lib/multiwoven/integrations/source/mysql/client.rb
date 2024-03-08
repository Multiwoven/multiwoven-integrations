# frozen_string_literal: true

require "mysql2"

module Multiwoven::Integrations::Source
  module Mysql
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        ConnectionStatus.new(
          status: ConnectionStatusType["succeeded"]
        ).to_multiwoven_message
      rescue Mysql2::Error => e
        ConnectionStatus.new(
          status: ConnectionStatusType["failed"], message: e.message
        ).to_multiwoven_message
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        query = "SELECT table_name, column_name, data_type, is_nullable
                 FROM information_schema.columns
                 WHERE table_schema = '#{connection_config[:database]}'
                 ORDER BY table_name, ordinal_position;"

        db = create_connection(connection_config)
        records = db.query(query).to_a
        catalog = Catalog.new(streams: create_streams(records))
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(
          "MYSQL:DISCOVER:EXCEPTION",
          "error",
          e
        )
      ensure
        db&.close
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
          "MYSQL:READ:EXCEPTION",
          "error",
          e
        )
      ensure
        db&.close
      end

      private

      def query(connection, query)
        result = connection.query(query)
        result.map do |row|
          RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
      end

      def create_connection(connection_config)
        raise "Unsupported Auth type" unless connection_config[:credentials][:auth_type] == "username/password"

        Mysql2::Client.new(
          host: connection_config[:host],
          database: connection_config[:database],
          username: connection_config[:credentials][:username],
          password: connection_config[:credentials][:password],
          port: connection_config[:port]
        )
      end

      def create_streams(records)
        return [] if records.nil? || records.empty?

        grouped_records = group_by_table(records)
        grouped_records.map do |table, columns|
          Multiwoven::Integrations::Protocol::Stream.new(
            name: table,
            action: StreamAction["fetch"],
            json_schema: convert_to_json_schema(columns)
          )
        end
      end

      def group_by_table(records)
        records.each_with_object({}) do |record, groups|
          table_name = record["TABLE_NAME"]
          groups[table_name] ||= []
          groups[table_name] << {
            column_name: record["COLUMN_NAME"],
            type: record["DATA_TYPE"],
            optional: record["IS_NULLABLE"] == "YES"
          }
        end
      end
    end
  end
end
