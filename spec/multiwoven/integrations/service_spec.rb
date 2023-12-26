# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Service do
  let(:service) { described_class.new }

  describe "#initialize" do
    it "initializes with a default config" do
      expect(service.send(:config)).to be_a(Multiwoven::Integrations::Config)
    end

    it "yields the config to a block if given" do
      expect { |b| described_class.new(&b) }.to yield_with_args(Multiwoven::Integrations::Config)
    end
  end

  describe "#connectors" do
    before do
      stub_const("Multiwoven::Integrations::ENABLED_SOURCES", ["TestSource"])
      stub_const("Multiwoven::Integrations::ENABLED_DESTINATIONS", ["TestDestination"])

      class_double("Multiwoven::Integrations::Source::TestSource::Client").as_stubbed_const
      class_double("Multiwoven::Integrations::Destination::TestDestination::Client").as_stubbed_const

      allow(Multiwoven::Integrations::Source::TestSource::Client).to receive(:new).and_return(double(meta_data: "source_meta"))
      allow(Multiwoven::Integrations::Destination::TestDestination::Client).to receive(:new).and_return(double(meta_data: "destination_meta"))
    end

    it "returns connectors with source and destination arrays" do
      expect(service.connectors).to eq(
        {
          source: ["source_meta"],
          destination: ["destination_meta"]
        }
      )
    end
  end
end
