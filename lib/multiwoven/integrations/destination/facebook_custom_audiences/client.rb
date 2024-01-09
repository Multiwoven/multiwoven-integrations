# frozen_string_literal: true

require "facebook_ads"

module Multiwoven::Integrations::Destination
  module FacebookCustomAudiences
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      def check_connection(connection_config)
        configure_facebook_ads(connection_config[:access_token])
        begin
          ad_accounts = fetch_ad_accounts
          if ad_account_exists?(ad_accounts, connection_config[:ad_account_id])
            ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
          else
            ConnectionStatus.new(status: ConnectionStatusType["failed"]).to_multiwoven_message
          end
        rescue FacebookAds::ClientError => e
          ConnectionStatus.new(status: ConnectionStatusType["failed"], message: e.message).to_multiwoven_message
        end
      end

      def configure_facebook_ads(access_token)
        FacebookAds.configure do |config|
          config.access_token = access_token
        end
      end

      def ad_account_exists?(ad_accounts, ad_account_id)
        ad_accounts.any? { |ad_account| ad_account.id == "act_#{ad_account_id}" }
      end

      def fetch_ad_accounts
        me = FacebookAds::User.get("me")
        me.adaccounts(fields: "id,name")
      end
    end
  end
end
