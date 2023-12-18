# frozen_string_literal: true

module Multiwoven::Integrations::Destination
  module Klaviyo
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector

      def check_connection(connection_config)
        api_key = connection_config[:private_api_key]
        url = "#{KLAVIYO_AUTH_ENDPOINT}?api_key=#{api_key}"

        response = Multiwoven::Integrations::Core::HttpClient.request(
          url, HTTP_GET,
          headers: { 'Accept' => 'application/json' }
        )
        parse_response(response)
      end

      private

      def parse_response(response)
        if response[:status] == '200'
          ConnectionStatus.new(status: ConnectionStatusType["succeeded"])
        else
          message = extract_message(response)
          ConnectionStatus.new(status: ConnectionStatusType["failed"], message: message)
        end
      end

      def extract_message(response)
        JSON.parse(response[:body])["message"] rescue "Klaviyo auth failed"
      end
    end
  end
end