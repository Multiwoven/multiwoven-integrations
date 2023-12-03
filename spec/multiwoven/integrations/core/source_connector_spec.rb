# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    RSpec.describe SourceConnector do
      describe "#spec" do
        it "raises an error for not being implemented" do
          connector = described_class.new
          expect { connector.spec }.to raise_error("Not implemented")
        end
      end

      describe "#check_connection" do
        it "raises an error for not being implemented" do
          connector = described_class.new
          expect { connector.check_connection({}) }.to raise_error("Not implemented")
        end
      end
    end
  end
end
