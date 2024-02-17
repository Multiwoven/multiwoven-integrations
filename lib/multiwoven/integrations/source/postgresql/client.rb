# frozen_string_literal: true

require "pg"

module Multiwoven::Integrations::Source
  module Postgresql
    include Multiwoven::Integrations::Core
    class Client < Multiwoven::Integrations::Source::Redshift::Client
    end
  end
end
