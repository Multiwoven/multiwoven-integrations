# frozen_string_literal: true

require 'stringio'
require 'logger'

module Multiwoven
  module Integrations
    module Destination
      module SalesforceCrm
        include Multiwoven::Integrations::Core

        API_VERSION = '59.0'.freeze 
        class Client < DestinationConnector
          def check_connection(connection_config)
            logger = initialize_logger
            client = initialize_client(connection_config, logger)

            authenticate_client(client)
            build_success_status
          rescue StandardError => e
            log_error(logger, e)
            build_failure_status(e)
          end

          private

          def initialize_logger
            Logger.new($stdout)
          end

          def initialize_client(config, logger)
            Restforce.new(
              oauth_token: config[:access_token],
              refresh_token: config[:refresh_token],
              instance_url: config[:instance_url],
              client_id: config[:client_id],
              client_secret: config[:client_secret],
              authentication_callback: proc { |x| logger.debug(x.to_s) },
              api_version: API_VERSION
            )
          end

          def authenticate_client(client)
            client.authenticate!
          end

          def build_success_status
            ConnectionStatus.new(status: ConnectionStatusType['succeeded'])
                            .to_multiwoven_message
          end

          def log_error(logger, error)
            logger.error("Authentication failed: #{error.message}")
          end

          def build_failure_status(error)
            ConnectionStatus.new(
              status: ConnectionStatusType['failed'],
              message: error.message
            ).to_multiwoven_message
          end
        end
      end
    end
  end
end
