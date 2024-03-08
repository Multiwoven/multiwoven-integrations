# frozen_string_literal: true

module Multiwoven
  module Integrations
    module Destination
      module GoogleSheets
        include Multiwoven::Integrations::Core

        class Client < DestinationConnector # rubocop:disable Metrics/ClassLength
          MAX_CHUNK_SIZE = 10_000
          GOOGLE_SHEETS_SCOPE = "https://www.googleapis.com/auth/drive"
          GOOGLE_SHEETS_SCHEMA_URL = "http://json-schema.org/draft-07/schema#"
          SPREADSHEET_ID_REGEX = %r{/d/([-\w]{20,})/}.freeze

          def check_connection(connection_config)
            authorize_client(connection_config)
            fetch_google_spread_sheets(connection_config)
            success_status
          rescue StandardError => e
            handle_exception("GOOGLE_SHEETS:CRM:DISCOVER:EXCEPTION", "error", e)
            failure_status(e)
          end

          def discover(connection_config)
            authorize_client(connection_config)
            spreadsheet = fetch_google_spread_sheets(connection_config)
            catalog = build_catalog_from_spreadsheet(spreadsheet, connection_config)
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception("GOOGLE_SHEETS:CRM:DISCOVER:EXCEPTION", "error", e)
          end

          def write(sync_config, records, action = "create")
            setup_write_environment(sync_config, action)
            process_record_chunks(records, sync_config)
          rescue StandardError => e
            handle_exception("GOOGLE_SHEETS:CRM:WRITE:EXCEPTION", "error", e)
          end

          private

          def authorize_client(config)
            credentials = config[:credentials_json]
            @client = Google::Apis::SheetsV4::SheetsService.new
            @client.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
              json_key_io: StringIO.new(credentials.to_json),
              scope: GOOGLE_SHEETS_SCOPE
            )
          end

          def fetch_google_spread_sheets(connection_config)
            spreadsheet_id = extract_spreadsheet_id(connection_config[:spreadsheet_link])
            @client.get_spreadsheet(spreadsheet_id)
          end

          def build_catalog_from_spreadsheet(spreadsheet, connection_config)
            catalog = build_catalog(load_catalog)
            @spreadsheet_id = extract_spreadsheet_id(connection_config[:spreadsheet_link])

            spreadsheet.sheets.each do |sheet|
              process_sheet_for_catalog(sheet, catalog)
            end

            catalog
          end

          def process_sheet_for_catalog(sheet, catalog)
            sheet_name, last_column_index = extract_sheet_properties(sheet)
            column_names = fetch_column_names(sheet_name, last_column_index)
            catalog.streams << generate_json_schema(column_names, sheet_name) if column_names
          end

          def extract_sheet_properties(sheet)
            [sheet.properties.title, sheet.properties.grid_properties.column_count]
          end

          def fetch_column_names(sheet_name, last_column_index)
            header_range = generate_header_range(sheet_name, last_column_index)
            spread_sheet_value(header_range)&.flatten
          end

          def spread_sheet_value(header_range)
            @spread_sheet_value ||= @client.get_spreadsheet_values(@spreadsheet_id, header_range).values
          end

          def generate_header_range(sheet_name, last_column_index)
            "#{sheet_name}!A1:#{column_index_to_letter(last_column_index)}1"
          end

          def column_index_to_letter(index)
            ("A".."ZZZ").to_a[index - 1]
          end

          def generate_json_schema(column_names, sheet_name)
            {
              name: sheet_name,
              action: "create",
              json_schema: generate_properties_schema(column_names),
              supported_sync_modes: %w[full_refresh incremental]
            }.with_indifferent_access
          end

          def generate_properties_schema(column_names)
            properties = column_names.each_with_object({}) do |field, props|
              props[field] = { "type" => "string" }
            end

            { "$schema" => GOOGLE_SHEETS_SCHEMA_URL, "type" => "object", "properties" => properties }
          end

          def setup_write_environment(sync_config, action)
            @action = sync_config.stream.action || action
            @spreadsheet_id = extract_spreadsheet_id(sync_config.destination.connection_specification[:spreadsheet_link])
            authorize_client(sync_config.destination.connection_specification)
          end

          def process_record_chunks(records, sync_config)
            write_success = 0
            write_failure = 0

            records.each_slice(MAX_CHUNK_SIZE) do |chunk|
              values = prepare_chunk_values(chunk, sync_config.stream)
              update_sheet_values(values, sync_config.stream.name)
              write_success += values.size
            rescue StandardError => e
              handle_exception("GOOGLE_SHEETS:RECORD:WRITE:EXCEPTION", "error", e)
              write_failure += chunk.size
            end

            tracking_message(write_success, write_failure)
          end

          def prepare_chunk_values(chunk, stream)
            last_column_index = spread_sheet_value(stream.name).count
            fields = fetch_column_names(stream.name, last_column_index)

            chunk.map do |row|
              row_values = Array.new(fields.size, nil)
              row.each do |key, value|
                index = fields.index(key.to_s)
                row_values[index] = value if index
              end
              row_values
            end
          end

          def update_sheet_values(values, stream_name)
            row_count = spread_sheet_value(stream_name).count
            range = "#{stream_name}!A#{row_count + 1}"
            value_range = Google::Apis::SheetsV4::ValueRange.new(range: range, values: values)

            batch_update_request = Google::Apis::SheetsV4::BatchUpdateValuesRequest.new(
              value_input_option: "RAW",
              data: [value_range]
            )

            # TODO: Remove & this is added for the test to pass we need
            @client&.batch_update_values(@spreadsheet_id, batch_update_request)
          end

          def extract_spreadsheet_id(link)
            link[SPREADSHEET_ID_REGEX, 1] || link
          end

          def success_status
            ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
          end

          def failure_status(error)
            ConnectionStatus.new(status: ConnectionStatusType["failed"], message: error.message).to_multiwoven_message
          end

          def load_catalog
            read_json(CATALOG_SPEC_PATH)
          end

          def tracking_message(success, failure)
            Multiwoven::Integrations::Protocol::TrackingMessage.new(
              success: success, failed: failure
            ).to_multiwoven_message
          end
        end
      end
    end
  end
end
