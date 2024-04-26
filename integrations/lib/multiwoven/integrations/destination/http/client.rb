# frozen_string_literal: true

module Multiwoven
  module Integrations
    module Destination
      module Airtable
        include Multiwoven::Integrations::Core
        class Client < DestinationConnector # rubocop:disable Metrics/ClassLength
          prepend Multiwoven::Integrations::Core::RateLimiter
          MAX_CHUNK_SIZE = 10
          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            destination_url = connection_config[:destination_url]
            request = Multiwoven::Integrations::Core::HttpClient.request(
              destination_url,
              HTTP_OPTIONS,
              headers: options_headers()
            )
            if success?(request)
              success_status
            else
              handle_exception("HTTP:CHECK_CONNECTION:EXCEPTION", "error", e)
              failure_status(nil)
            end
          rescue StandardError => e
            handle_exception("HTTP:CHECK_CONNECTION:EXCEPTION", "error", e)
            failure_status(e)
          end

          def discover(_connection_config = nil)
            catalog_json = read_json(CATALOG_SPEC_PATH)
    
            catalog = build_catalog(catalog_json)
    
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception(
              "HTTP:DISCOVER:EXCEPTION",
              "error",
            )
          end

          def write(sync_config, records, _action = "create")
            connection_config = sync_config.destination.connection_specification.with_indifferent_access
            api_key = connection_config[:api_key]
            url = sync_config.stream.url
            write_success = 0
            write_failure = 0
            records.each_slice(MAX_CHUNK_SIZE) do |chunk|
              payload = create_payload(chunk)
              response = Multiwoven::Integrations::Core::HttpClient.request(
                url,
                sync_config.stream.request_method,
                payload: payload,
                headers: auth_headers(api_key)
              )
              if success?(response)
                write_success += chunk.size
              else
                write_failure += chunk.size
              end
            rescue StandardError => e
              handle_exception("HTTP:RECORD:WRITE:EXCEPTION", "error", e)
              write_failure += chunk.size
            end

            tracker = Multiwoven::Integrations::Protocol::TrackingMessage.new(
              success: write_success,
              failed: write_failure
            )
            tracker.to_multiwoven_message
          rescue StandardError => e
            handle_exception("HTTP:WRITE:EXCEPTION", "error", e)
          end

          private

          def create_payload(records)
            {
              "records" => records.map do |record|
                {
                  "fields" => record
                }
              end
            }
          end

          def auth_headers(access_token)
            {
              "Accept" => "application/json",
              "Authorization" => "Bearer #{access_token}",
              "Content-Type" => "application/json"
            }
          end

          def options_headers()
            {
              "Access-Control-Allow-Methods": "POST"
            }
          end

          def extract_body(response)
            response_body = response.body
            JSON.parse(response_body) if response_body
          end
        end
      end
    end
  end
end