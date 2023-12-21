# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::Redshift::Client do
    let(:client) { Multiwoven::Integrations::Source::Redshift::Client.new }
    let(:sync_config) do
        {
          "source": {
            "name": "RedshiftSourceConnector",
            "type": "source",
            "connection_specification": {
              "credentials": {
                "auth_type": "username/password",
                "username": "REDSHIFT_USERNAME",
                "password": "REDSHIFT_PASSWORD"
              },
              "host": "example-redshift-cluster.abcdefg.us-west-2.redshift.amazonaws.com",
              "port": "5439", 
              "database": "REDSHIFT_DB",
              "schema": "REDSHIFT_SCHEMA"
            }
          },
          "model": {
            "name": "ExampleRedshiftModel",
            "query": "SELECT * FROM example_table LIMIT 10;",
            "query_type": "raw_sql",
            "primary_key": "id"
          },
          "sync_mode": "full_refresh",
          "cursor_field": ["timestamp"],
          "destination_sync_mode": "upsert"
        }
    end
    describe "#check_connection" do
      context "when the connection is successful" do
        it "returns a succeeded connection status" do
          allow(Sequel).to receive(:postgres).and_return(true)
  
          result = client.check_connection(sync_config[:source][:connection_specification])
          expect(result.status).to eq("succeeded")
          expect(result.message).to be_nil
        end
      end
  
      context "when the connection fails" do
        it "returns a failed connection status with an error message" do
          allow(PG).to receive(:connect).and_raise(PG::Error.new("Connection failed"))
      
          result = client.check_connection(sync_config[:source][:connection_specification])
          expect(result.status).to eq("failed")
          expect(result.message).to include("Connection failed")
        end
      end
    end
  
    # Define #read and #discover tests for Redshift
  end
  