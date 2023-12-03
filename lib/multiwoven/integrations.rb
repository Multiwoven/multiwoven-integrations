# frozen_string_literal: true

require "json"
require "dry-struct"
require "dry-schema"
require "dry-types"
require "byebug"
require_relative "integrations/version"
require_relative "integrations/core/utils"
require_relative "integrations/core/base_connector"
require_relative "integrations/core/source_connector"
require_relative "integrations/core/destination_connector"
require_relative "integrations/protocol/protocol"

module Multiwoven
  module Integrations
    class Error < StandardError; end
    # Your code goes here...
  end
end
