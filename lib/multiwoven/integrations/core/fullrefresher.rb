# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    module Fullrefresher
      prepend RateLimiter
      def write(sync_config, records, action = "insert")
        if sync_config && sync_config.sync_mode == "full_refresh" && !@refresher_called
          response = clear_all_records(sync_config)
          return response unless response &&
                                 response.control.status == Multiwoven::Integrations::Protocol::ConnectionStatusType["succeeded"]

          @refresher_called = true
        end

        super(sync_config, records, action)
      end
    end
  end
end
