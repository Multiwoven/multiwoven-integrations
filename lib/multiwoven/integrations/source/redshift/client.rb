# frozen_string_literal: true

require 'pg'

module Multiwoven::Integrations::Source
  module Redshift
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        create_connection(connection_config)
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"])
      rescue PG::Error => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message)
      end

      def discover(connection_config)
        query = "SELECT table_name, column_name, data_type, is_nullable
                 FROM information_schema.columns
                 WHERE table_schema = '#{connection_config[:schema]}' AND table_catalog = '#{connection_config[:database]}'
                 ORDER BY table_name, ordinal_position;"

        db = create_connection(connection_config)

        records = []
        db.exec(query) do |result|
          result.each do |row|
            records << row
          end
        end
        create_streams(records)
      ensure
        db.close if db
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification
        query = sync_config.model.query
        db = create_connection(connection_config)

        records = []
        db.exec(query) do |result|
          result.each do |row|
            records << RecordMessage.new(data: row, emitted_at: Time.now.to_i)
          end
        end

        records
      ensure
        db.close if db
      end

      private

      def create_connection(connection_config)
        raise "Unsupported Auth type" unless connection_config[:credentials][:auth_type] == "username/password"

        PG.connect(
          host: connection_config[:host],
          dbname: connection_config[:database],
          user: connection_config[:credentials][:username],
          password: connection_config[:credentials][:password],
          port: connection_config[:port]
        )
      end

      def create_streams(records)
        group_by_table(records).map do |table_name, columns|
          Multiwoven::Integrations::Protocol::Stream.new(name: table_name, json_schema: columns)
        end
      end

      def group_by_table(records)
        records.group_by { |entry| entry['table_name'] }.map do |table_name, columns|
          {
            tablename: table_name,
            columns: columns.map { |column| 
              { 
                column_name: column['column_name'], 
                type: column['data_type'], 
                optional: column['is_nullable'] == 'YES' 
              } 
            }
          }
        end
      end
    end
  end
end
