# frozen_string_literal: true

module Anvil
  class RateLimiter
    MAX_RETRIES = 3
    BASE_DELAY = 1.0  # Base delay in seconds

    attr_reader :max_retries, :base_delay

    def initialize(max_retries: MAX_RETRIES, base_delay: BASE_DELAY)
      @max_retries = max_retries
      @base_delay = base_delay
    end

    def with_retry
      retries = 0
      last_error = nil

      loop do
        begin
          response = yield

          # Check if we got rate limited
          if response.code == 429
            retries += 1
            if retries > max_retries
              raise RateLimitError.new(
                "Rate limit exceeded after #{max_retries} retries",
                response
              )
            end

            delay = calculate_delay(response, retries)
            sleep(delay)
            next
          end

          return response
        rescue Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET => e
          last_error = e
          retries += 1

          if retries > max_retries
            raise NetworkError.new(
              "Network error after #{max_retries} retries: #{e.message}"
            )
          end

          delay = exponential_backoff(retries)
          sleep(delay)
        end
      end
    end

    private

    def calculate_delay(response, retry_count)
      # Use Retry-After header if available
      if response.retry_after && response.retry_after > 0
        response.retry_after
      else
        exponential_backoff(retry_count)
      end
    end

    def exponential_backoff(retry_count)
      # Exponential backoff with jitter
      delay = base_delay * (2**(retry_count - 1))
      delay + (rand * delay * 0.1)  # Add 10% jitter
    end
  end
end