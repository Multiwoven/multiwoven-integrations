# frozen_string_literal: true

module Multiwoven
  module Integrations
    module Destination
      module Airtable
        module SchemaHelper
          module_function

          def clean_name(name_str)
            name_str.gsub(" ", "_").downcase.strip
          end

          def get_json_schema(table) # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
            properties = {}

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
                if complex_type == SCHEMA_TYPES[:ARRAY_WITH_ANY]
                  if original_type == "formula" && %w[number currency percent duration].include?(field_type)
                    complex_type = SCHEMA_TYPES[:NUMBER]
                  elsif original_type == "formula" && ARRAY_FORMULAS.none? { |x| options.fetch("formula", "").start_with?(x) }
                    complex_type = SCHEMA_TYPES[:STRING]
                  elsif SIMPLE_AIRTABLE_TYPES.keys.include?(field_type)
                    complex_type["items"] = Marshal.load(Marshal.dump(SIMPLE_AIRTABLE_TYPES[field_type]))
                  else
                    complex_type["items"] = SCHEMA_TYPES[:STRING]
                    # LOGGER.warn("Unknown field type: #{field_type}, falling back to `simpleText` type")
                  end
                end
                properties[name] = complex_type
              elsif SIMPLE_AIRTABLE_TYPES.keys.include?(original_type)
                field_type = exec_type || original_type
                properties[name] = Marshal.load(Marshal.dump(SIMPLE_AIRTABLE_TYPES[field_type]))
              else
                properties[name] = SCHEMA_TYPES[:STRING]
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
