# frozen_string_literal: true

module Multiwoven::Integrations::Destination
  module FacebookCustomAudiences
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      def check_connection(connection_config)
        access_token = connection_config[:access_token]
        response = Multiwoven::Integrations::Core::HttpClient.request(
          FACEBOOK_AUDIENCE_GET_ALL_ACCOUNTS,
          HTTP_GET,
          headers: auth_headers(access_token)
        )
        if success?(response)
          ad_account_exists?(response, connection_config[:ad_account_id])
          ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
        else
          ConnectionStatus.new(status: ConnectionStatusType["failed"]).to_multiwoven_message
        end
      rescue StandardError => e
        ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
      end

      def discover
        catalog_json = read_json(CATALOG_SPEC_PATH)

        streams = catalog_json["streams"].map do |stream|
          Multiwoven::Integrations::Protocol::Stream.new(
            name: stream["name"],
            json_schema: stream["json_schema"],
            url: stream["url"],
            method: stream["method"],
            action: stream["action"]
          )
        end

        catalog = Multiwoven::Integrations::Protocol::Catalog.new(
          streams: streams
        )

        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(
          "FACEBOOK AUDIENCE:DISCOVER:EXCEPTION",
          "error",
          e
        )
      end

      def auth_headers(access_token)
        {
          "Accept" => "application/json",
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        }
      end

      def ad_account_exists?(response, ad_account_id)
        return if extract_data(response).any? { |ad_account| ad_account["id"] == formatted_ad_account_id(ad_account_id) }

        raise ArgumentError, "Ad account not found in business account"
      end

      def success?(response)
        response && %w[200 201].include?(response.code.to_s)
      end

      def extract_data(response)
        response_body = response.body
        JSON.parse(response_body)["data"] if response_body
      end

      def formatted_ad_account_id(ad_account_id)
        "act_#{ad_account_id}"
      end
    end
  end
end
