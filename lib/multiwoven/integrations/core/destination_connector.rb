# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    # TODO: enforce method signatures using sorbet
    class DestinationConnector < BaseConnector
      def write(_connection_config, _sync_config, _records)
        raise "Not implemented"
        # return list of record message
      end
    end
  end
end
