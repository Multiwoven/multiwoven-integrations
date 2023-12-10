# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::Snowflake::Client do
  describe "#check_connection" do
    let(:client) { Multiwoven::Integrations::Source::Snowflake::Client.new }

    let(:connection_config) do
      {
        credentials: {
          auth_type: "username/password",
          username: "test_user",
          password: "test_password"
        },
        host: "test_host",
        warehouse: "test_warehouse",
        database: "test_database",
        schema: "test_schema"
      }
    end

    context "when the connection is successful" do
      it "returns a succeeded connection status" do
        allow(Sequel).to receive(:odbc).and_return(true)

        result = client.check_connection(connection_config)
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(Sequel).to receive(:odbc).and_raise(Sequel::DatabaseConnectionError, "Connection failed")

        result = client.check_connection(connection_config)
        expect(result.status).to eq("failed")
        expect(result.message).to eq("Connection failed")
      end
    end
  end
end
