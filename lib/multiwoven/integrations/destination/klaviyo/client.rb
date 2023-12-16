# frozen_string_literal: true

module Multiwoven::Integrations::Destination
    module Klaviyo
      include Multiwoven::Integrations::Core
      class Client < DestinationConnector
      end
    end
end