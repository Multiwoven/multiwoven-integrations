# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class BaseConnector
      def spec
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
