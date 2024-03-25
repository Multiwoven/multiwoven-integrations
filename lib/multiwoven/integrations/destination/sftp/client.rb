# frozen_string_literal: true

module Multiwoven::Integrations::Destination
  module Sftp
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      prepend Multiwoven::Integrations::Core::Fullrefresher
      prepend Multiwoven::Integrations::Core::RateLimiter

      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        with_sftp_client(connection_config) do |sftp|
          stream = SecureRandom.uuid
          test_path = "/path/to/test/#{stream}"
          test_file_operations(sftp, test_path)
          return success_status
        end
      rescue StandardError => e
        handle_exception("SFTP:CHECK_CONNECTION:EXCEPTION", "error", e)
        failure_status(e)
      end

      def discover(_connection_config = nil)
        catalog_json = read_json(CATALOG_SPEC_PATH)

        catalog = build_catalog(catalog_json)

        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(
          "SFTP:DISCOVER:EXCEPTION",
          "error",
          e
        )
      end

      def write(sync_config, records, _action = "insert")
        connection_config = sync_config.destination.connection_specification.with_indifferent_access
        file_path = generate_file_path(sync_config)
        csv_content = generate_csv_content(records)
        write_success = 0
        write_failure = 0
        # 10000 records in single
        with_sftp_client(connection_config) do |sftp|
          sftp.file.open(file_path, "w") { |file| file.puts(csv_content) }
          write_success += records.size
        rescue StandardError => e
          handle_exception("SFTP:RECORD:WRITE:EXCEPTION", "error", e)
          write_failure += records.size
        end
        tracking_message(write_success, write_failure)
      rescue StandardError => e
        handle_exception(
          "SFTP:WRITE:EXCEPTION",
          "error",
          e
        )
      end

      def clear_all_records(sync_config)
        connection_specification = sync_config.destination.connection_specification.with_indifferent_access
        with_sftp_client(connection_specification) do |sftp|
          files = sftp.dir.glob(connection_specification[:destination_path], "*")

          files.each do |file|
            sftp.remove!(File.join(connection_specification[:destination_path], file.name))
          end
          if sftp.dir.entries(connection_specification[:destination_path]).size == 2
            control_message("Successfully cleared data.", "succeeded")
          else
            control_message("Failed to clear data.", "failed")
          end
        end
      rescue StandardError => e
        control_message(e.message, "failed")
      end

      private

      def generate_file_path(sync_config)
        timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
        file_name = "#{sync_config.stream.name}_#{timestamp}.csv"
        File.join(sync_config.destination.connection_specification[:destination_path], file_name)
      end

      def generate_csv_content(records)
        CSV.generate do |csv|
          headers = records.first.keys
          csv << headers
          records.each { |record| csv << record.values_at(*headers) }
        end
      end

      def tracking_message(success, failure)
        Multiwoven::Integrations::Protocol::TrackingMessage.new(
          success: success, failed: failure
        ).to_multiwoven_message
      end

      def with_sftp_client(connection_config, &block)
        Net::SFTP.start(
          connection_config[:host],
          connection_config[:username],
          password: connection_config[:password],
          port: connection_config.fetch(:port, 22), &block
        )
      end

      def test_file_operations(sftp, test_path)
        sftp.file.open(test_path, "w") { |file| file.puts("connection_check") }
        sftp.remove!(test_path)
      end

      def control_message(message, status)
        ControlMessage.new(
          type: "full_refresh",
          emitted_at: Time.now.to_i,
          status: ConnectionStatusType[status],
          meta: { detail: message }
        ).to_multiwoven_message
      end
    end
  end
end