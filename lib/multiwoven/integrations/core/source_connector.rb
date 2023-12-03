# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    # TODO: enforce method signatures using sorbet
    class SourceConnector < BaseConnector
      def discover(_connection_spec)
        raise "Not implemented"
        # return catalog
      end

      def read(_connection_config, _sync_config)
        raise "Not implemented"
        # return list of record message
      end
    end
  end
end
