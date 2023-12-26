# frozen_string_literal: true

module Multiwoven::Integrations::Destination
  module SalesforceCrm
    include Multiwoven::Integrations::Core

    class Client < DestinationConnector
      def check_connection(connection_config)
        logger = Logger.new($stdout)
        client = Restforce.new(oauth_token: connection_config[:access_token],
                               refresh_token: connection_config[:refresh_token],
                               instance_url: connection_config[:instance_url],
                               client_id: connection_config[:client_id],
                               client_secret: connection_config[:client_secret],
                               authentication_callback: proc { |x| logger.debug(x.to_s) },
                               api_version: "41.0")

        client.describe
      end
    end
  end
end
