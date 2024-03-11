# frozen_string_literal: true

module Multiwoven
  module Integrations
    module Destination
      module Airtable
        include Multiwoven::Integrations::Core
        class Client < DestinationConnector # rubocop:disable Metrics/ClassLength
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
              name: "#{base_name}/#{clean_name(table["name"])}",
              action: "create",
              json_schema: get_json_schema(table),
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

          def clean_name(name_str)
            name_str.gsub(" ", "_").downcase.strip
          end

          def get_json_schema(table) # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
            properties = {
              "_airtable_id" => SCHEMA_TYPES[:STRING],
              "_airtable_created_time" => SCHEMA_TYPES[:STRING],
              "_airtable_table_name" => SCHEMA_TYPES[:STRING]
            }

            fields = table["fields"] || {}
            fields.each do |field|
              name = clean_name(field.fetch("name", ""))
              original_type = field.fetch("type", "")
              options = field.fetch("options", {})
              options_result = options.fetch("result", {})
              exec_type = options_result["type"] unless options_result.empty?

              if COMPLEX_AIRTABLE_TYPES.keys.include?(original_type)
                complex_type = Marshal.load(Marshal.dump(COMPLEX_AIRTABLE_TYPES[original_type]))

                field_type = exec_type || "simpleText"
                if complex_type == :ARRAY_WITH_ANY
                  if original_type == "formula" && %w[number currency percent duration].include?(field_type)
                    complex_type = :NUMBER
                  elsif original_type == "formula" && ARRAY_FORMULAS.none? { |x| options.fetch("formula", "").start_with?(x) }
                    complex_type = :STRING
                  elsif SIMPLE_AIRTABLE_TYPES.keys.include?(field_type)
                    complex_type["items"] = DeepClone.clone(SIMPLE_AIRTABLE_TYPES[field_type])
                  else
                    complex_type["items"] = :STRING
                    # LOGGER.warn("Unknown field type: #{field_type}, falling back to `simpleText` type")
                  end
                end
                properties[name] = complex_type
              elsif SIMPLE_AIRTABLE_TYPES.keys.include?(original_type)
                field_type = exec_type || original_type
                properties[name] = Marshal.load(Marshal.dump(SIMPLE_AIRTABLE_TYPES[field_type]))
              else
                properties[name] = :STRING
              end
            end

            {
              "$schema" => "https://json-schema.org/draft-07/schema#",
              "type" => "object",
              "additionalProperties" => true,
              "properties" => properties
            }
          end

          SCHEMA_TYPES = {
            STRING: { "type": %w[null string] },
            NUMBER: { "type": %w[null number] },
            BOOLEAN: { "type": %w[null boolean] },
            DATE: { "type": %w[null string], "format": "date" },
            DATETIME: { "type": %w[null string], "format": "date-time" },
            ARRAY_WITH_STRINGS: { "type": %w[null array], "items": { "type": %w[null string] } },
            ARRAY_WITH_ANY: { "type": %w[null array], "items": {} }
          }.freeze

          SIMPLE_AIRTABLE_TYPES = {
            "multipleAttachments" => SCHEMA_TYPES[:STRING],
            "autoNumber" => SCHEMA_TYPES[:NUMBER],
            "barcode" => SCHEMA_TYPES[:STRING],
            "button" => SCHEMA_TYPES[:STRING],
            "checkbox" => :BOOLEAN,
            "singleCollaborator" => SCHEMA_TYPES[:STRING],
            "count" => SCHEMA_TYPES[:NUMBER],
            "createdBy" => SCHEMA_TYPES[:STRING],
            "createdTime" => SCHEMA_TYPES[:DATETIME],
            "currency" => SCHEMA_TYPES[:NUMBER],
            "email" => SCHEMA_TYPES[:STRING],
            "date" => SCHEMA_TYPES[:DATE],
            "dateTime" => SCHEMA_TYPES[:DATETIME],
            "duration" => SCHEMA_TYPES[:NUMBER],
            "lastModifiedBy" => SCHEMA_TYPES[:STRING],
            "lastModifiedTime" => SCHEMA_TYPES[:DATETIME],
            "multipleRecordLinks" => SCHEMA_TYPES[:ARRAY_WITH_STRINGS],
            "multilineText" => SCHEMA_TYPES[:STRING],
            "multipleCollaborators" => SCHEMA_TYPES[:ARRAY_WITH_STRINGS],
            "multipleSelects" => SCHEMA_TYPES[:ARRAY_WITH_STRINGS],
            "number" => SCHEMA_TYPES[:NUMBER],
            "percent" => SCHEMA_TYPES[:NUMBER],
            "phoneNumber" => SCHEMA_TYPES[:STRING],
            "rating" => SCHEMA_TYPES[:NUMBER],
            "richText" => SCHEMA_TYPES[:STRING],
            "singleLineText" => SCHEMA_TYPES[:STRING],
            "singleSelect" => SCHEMA_TYPES[:STRING],
            "externalSyncSource" => SCHEMA_TYPES[:STRING],
            "url" => SCHEMA_TYPES[:STRING],
            "simpleText" => SCHEMA_TYPES[:STRING]
          }.freeze

          COMPLEX_AIRTABLE_TYPES = {
            "formula" => SCHEMA_TYPES[:ARRAY_WITH_ANY],
            "lookup" => SCHEMA_TYPES[:ARRAY_WITH_ANY],
            "multipleLookupValues" => SCHEMA_TYPES[:ARRAY_WITH_ANY],
            "rollup" => SCHEMA_TYPES[:ARRAY_WITH_ANY]
          }.freeze

          ARRAY_FORMULAS = %w[ARRAYCOMPACT ARRAYFLATTEN ARRAYUNIQUE ARRAYSLICE].freeze
        end
      end
    end
  end
end
