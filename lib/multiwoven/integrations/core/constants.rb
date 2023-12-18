# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    module Constants
      META_DATA_PATH = "config/meta.json"
      CONNECTOR_SPEC_PATH = "config/spec.json"
      INTEGRATIONS_PATH = "#{Dir.pwd}/lib/multiwoven/integrations/"
      SNOWFLAKE_DRIVER_PATH = "/opt/snowflake/snowflakeodbc/lib/universal/libSnowflake.dylib"

      KLAVIYO_AUTH_ENDPOINT = 'https://a.klaviyo.com/api/v2/lists/'

      # HTTP
      HTTP_GET = 'GET'
      HTTP_POST = 'POST'
      HTTP_PUT = 'PUT'
      HTTP_DELETE = 'DELETE'
    end
  end
end
