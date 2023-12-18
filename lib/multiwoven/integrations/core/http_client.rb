# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class HttpClent
      
      class << self

        def request(url, method, payload: nil, headers: {}) 
          uri = URI(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == 'https')
    
          request = build_request(method, uri, payload, headers)
    
          http.request(request)
        end
    
        private
    
        def build_request(method, uri, payload, headers)
          request_class = case method.upcase
            when 'GET' then Net::HTTP::Get
            when 'POST' then Net::HTTP::Post
            when 'PUT' then Net::HTTP::Put
            when 'DELETE' then Net::HTTP::Delete
            else raise ArgumentError, "Unsupported HTTP method: #{method}"
            end

          request = request_class.new(uri)
    
          headers.each { |key, value| request[key] = value }
          request.body = payload.to_json if payload && %w[POST PUT].include?(method.upcase)
          request
        end
      end
    end
  end
end