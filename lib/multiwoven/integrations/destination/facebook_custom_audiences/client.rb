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
            audience_id: stream["audience_id"],
            url: stream["url"],
            name: stream["name"],
            json_schema: stream["json_schema"],
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

      def write(sync_config, records, _action = "insert")
        url = sync_config.stream.url
        request_method = sync_config.stream.request_method

        write_success = 0
        write_failure = 0
        records.each do |record|
          schema = record.data.keys
          data = schema.map { |field| record.data[field] }
          payload = {
            "payload" => {
              "schema" => schema,
              "data" => [data]
            }
          }
          response = Multiwoven::Integrations::Core::HttpClient.request(
            url,
            request_method,
            payload: payload,
            headers: auth_headers(access_token)
          )
          if success?(response)
            write_success += 1
          else
            write_failure += 1
          end
        rescue StandardError => e
          logger.error(
            "FACEBOOK:RECORD:WRITE:FAILURE: #{e.message}"
          )
          write_failure += 1
        end
        tracker = Multiwoven::Integrations::Protocol::TrackingMessage.new(
          success: write_success,
          failed: write_failure
        )
        tracker.to_multiwoven_message
      rescue StandardError => e
        # TODO: Handle rate limiting seperately
        handle_exception(
          "FACEBOOK:WRITE:EXCEPTION",
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
