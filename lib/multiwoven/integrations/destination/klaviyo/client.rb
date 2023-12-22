# frozen_string_literal: true

module Multiwoven::Integrations::Destination
  module Klaviyo
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      def check_connection(connection_config)
        api_key = connection_config[:private_api_key]

        response = Multiwoven::Integrations::Core::HttpClient.request(
          KLAVIYO_AUTH_ENDPOINT,
          HTTP_POST,
          payload: KLAVIYO_AUTH_PAYLOAD,
          headers: {
            "Accept" => "application/json",
            "Authorization" => "Klaviyo-API-Key #{api_key}",
            "Revision" => "2023-02-22",
            "Content-Type" => "application/json"
          }
        )
        parse_response(response)
      end

      def discover
        catalog = read_json(CATALOG_SPEC_PATH)

        catalog["streams"].map do |stream|
          Multiwoven::Integrations::Protocol::Stream.new(
            name: stream["name"],
            json_schema: stream["json_schema"],
            url: stream["url"],
            method: stream["method"],
            action: stream["action"]
          )
        end
      end

      private

      def parse_response(response)
        if response && %w[200 201].include?(response.code)
          ConnectionStatus.new(status: ConnectionStatusType["succeeded"])
        else
          message = extract_message(response)
          ConnectionStatus.new(status: ConnectionStatusType["failed"], message: message)
        end
      end

      def extract_message(response)
        JSON.parse(response.body)["message"]
      rescue StandardError => e
        "Klaviyo auth failed: #{e.message}"
      end
    end
  end
end
