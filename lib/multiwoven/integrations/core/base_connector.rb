# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    # TODO: enforce method signatures using sorbet
    class BaseConnector
      def connector_spec
        # return connector spec
        raise "Not implemented"
      end

      def check_connection(_config)
        raise "Not implemented"
        # return connection status
      end
    end
  end
end
