# frozen_string_literal: true

require "json"
require "dry-struct"
require "dry-schema"
require "dry-types"
require "odbc"
require "sequel"
require "byebug"
require "net/http"
require "uri"
require "active_support/core_ext/hash/indifferent_access"
require "restforce"
require "logger"
require "slack-ruby-client"
require "git"
require "ruby-limiter"
require "hubspot-api-client"
require "google/apis/sheets_v4"

# Service
require_relative "integrations/config"
require_relative "integrations/rollout"
require_relative "integrations/service"

# Core
require_relative "integrations/core/constants"
require_relative "integrations/core/utils"
require_relative "integrations/core/rate_limiter"
require_relative "integrations/protocol/protocol"
require_relative "integrations/core/base_connector"
require_relative "integrations/core/source_connector"
require_relative "integrations/core/destination_connector"
require_relative "integrations/core/http_client"

# Source
require_relative "integrations/source/snowflake/client"
require_relative "integrations/source/redshift/client"
require_relative "integrations/source/bigquery/client"
require_relative "integrations/source/postgresql/client"
require_relative "integrations/source/databricks/client"

# Destination
require_relative "integrations/destination/klaviyo/client"
require_relative "integrations/destination/salesforce_crm/client"
require_relative "integrations/destination/facebook_custom_audience/client"
require_relative "integrations/destination/slack/client"
require_relative "integrations/destination/hubspot/client"
require_relative "integrations/destination/google_sheets/client"

module Multiwoven
  module Integrations
    class Error < StandardError; end
    # Your code goes here...
  end
end
