# frozen_string_literal: true

require 'stringio'

module Multiwoven
  module Integrations
    module Destination
      module SalesforceCrm
        include Multiwoven::Integrations::Core

        API_VERSION = '59.0'

        class Client < DestinationConnector
          def check_connection(connection_config)
            setup_client(connection_config)
            authenticate_client
            success_status
          rescue StandardError => e
            failure_status(e)
          end

          def discover
            catalog = build_catalog(load_catalog_streams)
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_discovery_exception(e)
          end

          def write(sync_config, records, action = 'create')
            setup_client(sync_config[:destination][:connection_specification])
            process_records(records, sync_config[:streams])
          rescue StandardError => e
            handle_write_exception(e)
          end

          private

          def setup_client(connection_config)
            @client ||= initialize_client(connection_config)
          end

          def process_records(records, stream)
            write_success, write_failure = 0, 0
            properties = stream[:json_schema][:properties]

            records.each do |record_object|
              record = extract_data(record_object, properties)
              process_record(stream, record)
              write_success += 1
            rescue StandardError => e
              handle_write_exception(e)
              write_failure += 1
            end

            tracking_message(write_success, write_failure)
          end

          def process_record(stream, record)
            send_data_to_salesforce(stream[:action], stream[:name], record)
          end

          def send_data_to_salesforce(action, stream_name, record = {})
            method_name = "#{action}!"
            args = build_args(action, stream_name, record)
            @client.send(method_name, *args)
          end

          def build_args(action, stream_name, record)
            case action
            when :upsert
              [stream_name, record[:external_key], record]
            when :destroy
              [stream_name, record[:id]]
            else
              [stream_name, record]
            end
          end

          def initialize_client(config)
            Restforce.new(
              oauth_token: config[:access_token],
              refresh_token: config[:refresh_token],
              instance_url: config[:instance_url],
              client_id: config[:client_id],
              client_secret: config[:client_secret],
              authentication_callback: proc { |x| log_debug(x.to_s) },
              api_version: API_VERSION
            )
          end

          def authenticate_client
            @client.authenticate!
          end

          def success_status
            ConnectionStatus.new(status: ConnectionStatusType['succeeded']).to_multiwoven_message
          end

          def failure_status(error)
            ConnectionStatus.new(status: ConnectionStatusType['failed'], message: error.message).to_multiwoven_message
          end

          def load_catalog_streams
            catalog_json = read_json(CATALOG_SPEC_PATH)
            catalog_json['streams'].map { |stream| build_stream(stream) }
          end

          def build_stream(stream)
            Multiwoven::Integrations::Protocol::Stream.new(
              name: stream['name'],
              json_schema: stream['json_schema'],
              action: stream['action']
            )
          end

          def build_catalog(streams)
            Multiwoven::Integrations::Protocol::Catalog.new(streams: streams)
          end

          def tracking_message(success, failure)
            Multiwoven::Integrations::Protocol::TrackingMessage.new(
              success: success,
              failed: failure
            ).to_multiwoven_message
          end

          def handle_discovery_exception(exception)
            handle_exception("SALESFORCE:CRM:DISCOVER:EXCEPTION", "error", exception)
          end

          def handle_write_exception(exception)
            handle_exception("SALESFORCE:CRM:WRITE:EXCEPTION", "error", exception)
          end

          def log_debug(message)
            Multiwoven::Integrations::Service.logger.debug(message)
          end
        end
      end
    end
  end
end
