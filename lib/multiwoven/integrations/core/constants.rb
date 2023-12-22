# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    module Constants
      INTEGRATIONS_PATH = "#{Dir.pwd}/lib/multiwoven/integrations/"
      META_DATA_PATH = "config/meta.json"
      CONNECTOR_SPEC_PATH = "config/spec.json"
      CATALOG_SPEC_PATH = "config/catalog.json"
      SNOWFLAKE_DRIVER_PATH = "/opt/snowflake/snowflakeodbc/lib/universal/libSnowflake.dylib"

      KLAVIYO_AUTH_ENDPOINT = "https://a.klaviyo.com/api/lists/"
      KLAVIYO_AUTH_PAYLOAD = {
        data: {
          type: "list",
          attributes: {
            name: "THIS IS REQUIRED"
          }
        }
      }.freeze

      # HTTP
      HTTP_GET = "GET"
      HTTP_POST = "POST"
      HTTP_PUT = "PUT"
      HTTP_DELETE = "DELETE"
    end
  end
end
