# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class DestinationConnector < BaseConnector
      # TODO: Add sync type insert, update, delete as argument
      def write(_sync_config, _records)
        raise "Not implemented"
        # return list of record message
      end
    end
  end
end
