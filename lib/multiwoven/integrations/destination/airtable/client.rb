# frozen_string_literal: true

module Multiwoven
  module Integrations
    module Destination
      module Airtable
        include Multiwoven::Integrations::Core

        class Client < DestinationConnector
          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            access_token = connection_config[:access_token]

            response = Multiwoven::Integrations::Core::HttpClient.request(
              AIRTABLE_AUTH_ENDPOINT,
              HTTP_GET,
              headers: auth_headers(access_token)
            )
            parse_response(response)
          end

          private

          def parse_response(response)
            if success?(response)
              success_status
            else
              message = extract_message(response)
              failure_status(message)
            end
          end

          def extract_message(response)
            JSON.parse(response.body)["message"]
          rescue StandardError => e
            "Airtable auth failed: #{e.message}"
          end

          def auth_headers(access_token)
            {
              "Accept" => "application/json",
              "Authorization" => "Bearer #{access_token}",
              "Content-Type" => "application/json"
            }
          end

          def load_catalog
            read_json(CATALOG_SPEC_PATH)
          end
        end
      end
    end
  end
end
