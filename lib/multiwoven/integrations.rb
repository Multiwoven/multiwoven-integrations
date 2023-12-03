# frozen_string_literal: true

require "json"
require "dry-struct"
require "dry-schema"
require "dry-types"
require "byebug"
require_relative "integrations/version"
require_relative "integrations/protocol/protocol"

module Multiwoven
  module Integrations
    class Error < StandardError; end
    # Your code goes here...
  end
end
