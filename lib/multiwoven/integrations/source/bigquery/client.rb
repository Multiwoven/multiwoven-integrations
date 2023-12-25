# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module Bigquery
    include Multiwoven::Integrations::Core
    class Client < SourceConnector

      def check_connection(connection_config)
        puts connection_config
        
      end
    end
  end
end
