# encoding: utf-8
module Pioneer
  class Request
    attr_reader :pioneer, :url, :result, :response
    def initialize(url, pioneer)
      @url, @pioneer = url, pioneer
      @url = begin
        url = "http://" + url unless url =~ /http/
        URI.escape(url)
      end
    end

    def perform
      pioneer.logger.info("going to #{url}")
      @result = handle_request_error_or_return_result
    end

    # Handle base fatal request error
    def handle_request_error_or_return_result
      begin
        @response = EventMachine::HttpRequest.new(url).get(pioneer.http_opts)
      rescue => e
        error = "Request totaly failed. Url: #{url}, error: #{e.message}"
        pioneer.logger.fatal(error)
        if pioneer.respond_to? :if_request_error
          return pioneer.send(:if_request_error, self)
        else
          raise HttpRequestError, error
        end
      end
      handle_response_error_or_return_result
    end

    # handle http error
    def handle_response_error_or_return_result
      if response.error
        error = "Response for #{url} get an error: #{response.error}"
        pioneer.logger.error(error)
        if pioneer.respond_to? :if_response_error
          return pioneer.send(:if_response_error, self)
        else
          raise HttpResponseError, error
        end
      end
      handle_status_or_return_result
    end

    def handle_status_or_return_result
      status = response.response_header.status
      case status
      when 200
        pioneer.processing(self)
      else
        pioneer.logger.error("This #{url} returns this http status: #{status}")
        if pioneer.respond_to? "if_status_#{status}".to_sym
          pioneer.send("if_status_#{status}", self)
        elsif pioneer.respond_to? :if_status_not_200
          pioneer.send(:if_status_not_200, self)
        else
          nil # nothing?
        end
      end
    end
  end
end