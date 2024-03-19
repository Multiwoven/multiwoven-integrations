# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class DestinationConnector < BaseConnector
      prepend Fullrefresher
      prepend RateLimiter

      # Records are transformed json payload send it to the destination
      # SyncConfig is the Protocol::SyncConfig object
      def write(_sync_config, _records, _action = "insert")
        raise "Not implemented"
        # return Protocol::TrackingMessage
      end

      private

      def clear_all_records(_sync_config)
        # Logic to clear all records at the destination
        # implementation needed to support full_refresh sync mode.
        # Return type is ControlMessage < ProtocolModel
        raise "Not implemented clear_all_records"
      end
    end
  end
end
