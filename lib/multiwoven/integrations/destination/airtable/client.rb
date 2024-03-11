# frozen_string_literal: true

require_relative "schema_helper"
module Multiwoven
  module Integrations
    module Destination
      module Airtable
        include Multiwoven::Integrations::Core
        class Client < DestinationConnector
          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            bases = Multiwoven::Integrations::Core::HttpClient.request(
              AIRTABLE_BASES_ENDPOINT,
              HTTP_GET,
              headers: auth_headers(connection_config[:api_key])
            )
            if success?(bases)
              base_id_exists?(bases, connection_config[:base_id])
              success_status
            else
              failure_status(nil)
            end
          rescue StandardError => e
            failure_status(e.message)
          end

          def discover(connection_config)
            connection_config = connection_config.with_indifferent_access
            base_id = connection_config[:base_id]
            api_key = connection_config[:api_key]

            bases = Multiwoven::Integrations::Core::HttpClient.request(
              AIRTABLE_BASES_ENDPOINT,
              HTTP_GET,
              headers: auth_headers(api_key)
            )

            base = extract_data(bases).find { |b| b["id"] == base_id }
            base_name = base["name"]

            schema = Multiwoven::Integrations::Core::HttpClient.request(
              AIRTABLE_GET_BASE_SCHEMA_ENDPOINT.gsub("{baseId}", base_id),
              HTTP_GET,
              headers: auth_headers(api_key)
            )

            catalog = build_catalog_from_schema(JSON.parse(schema.body), base_id, base_name)
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception("AIRTABLE:DISCOVER:EXCEPTION", "error", e)
          end

          def write(_sync_config, _records, _action = "create")
            # setup_write_environment(sync_config, action)
            # process_record_chunks(records, sync_config)
          rescue StandardError => e
            handle_exception("AIRTABLE:WRITE:EXCEPTION", "error", e)
          end

          private

          def auth_headers(access_token)
            {
              "Accept" => "application/json",
              "Authorization" => "Bearer #{access_token}",
              "Content-Type" => "application/json"
            }
          end

          def base_id_exists?(bases, base_id)
            return if extract_data(bases).any? { |base| base["id"] == base_id }

            raise ArgumentError, "Ad account not found in business account"
          end

          def extract_data(response)
            response_body = response.body
            JSON.parse(response_body)["bases"] if response_body
          end

          def load_catalog
            read_json(CATALOG_SPEC_PATH)
          end

          def create_stream(table, base_id, base_name)
            {
              name: "#{base_name}/#{SchemaHelper.clean_name(table["name"])}",
              action: "create",
              json_schema: SchemaHelper.get_json_schema(table),
              supported_sync_modes: %w[full_refresh incremental],
              url: "#{AIRTABLE_URL_BASE}#{base_id}/#{table["name"]}",
              batch_support: true,
              batch_size: 10

            }.with_indifferent_access
          end

          def build_catalog_from_schema(schema, base_id, base_name)
            catalog = build_catalog(load_catalog)
            schema["tables"].each do |table|
              catalog.streams << create_stream(table, base_id, base_name)
            end
            catalog
          end
        end
      end
    end
  end
end
