# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module Snowflake
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        create_connection(connection_config)
        ConnectionStatus.new(status: ConnectionStatusType["succeeded"])
      rescue Sequel::DatabaseConnectionError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message)
      end

      def discover(_connection_config)
        # get connection
        # query to get all tables and fields
        # create catalog
        # return catalog
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification
        query = sync_config.model.query
        db = create_connection(connection_config)

        records = []
        db.fetch(query) do |row|
          records << RecordMessage.new(data: row, emitted_at: Time.now.to_i)
        end

        records
      end

      private

      def create_connection(connection_config)
        raise "Unsupported Auth type" if connection_config[:credentials][:auth_type] != "username/password"

        Sequel.odbc(drvconnect: generate_drvconnect(connection_config))
      end

      def generate_drvconnect(connection_config)
        username = connection_config[:credentials][:username]
        password = connection_config[:credentials][:password]
        host = connection_config[:host]
        warehouse = connection_config[:warehouse]
        database = connection_config[:database]
        schema = connection_config[:schema]

        "driver=#{SNOWFLAKE_DRIVER_PATH};server=#{host};uid=#{username};pwd=#{password};schema=#{schema};database=#{database};warehouse=#{warehouse};"
      end
    end
  end
end
