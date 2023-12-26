# frozen_string_literal: true

# frozen_string_literal: true

module Multiwoven
  module Integrations
    class Service
      def initialize
        yield(config) if block_given?
      end

      def connectors
        {
          source: build_connectors(ENABLED_SOURCES, "Source"),
          destination: build_connectors(ENABLED_DESTINATIONS, "Destination")
        }
      end

      def connector_class(connector_type, connector_name)
        Object.const_get("Multiwoven::Integrations::#{connector_type}::#{connector_name}::Client")
      end

      private

      def build_connectors(enabled_connectors, type)
        enabled_connectors.map do |connector|
          connector_class(
            type, connector
          ).new.meta_data
        end
      end

      def config
        @config ||= Config.new
      end
    end
  end
end
