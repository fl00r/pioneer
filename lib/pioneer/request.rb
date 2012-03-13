# encoding: utf-8
module Pioneer
  class Request
    attr_reader :pioneer, :url, :result, :response, :error, :counter
    
    def initialize(url, pioneer, counter=0)
      @pioneer = pioneer
      @url     = parse_url(url)
      @counter = counter
    end

    #
    # Request processing
    #
    def perform
      pioneer.logger.info("going to #{url}")
      @result = handle_request_error_or_return_result
    end

    #
    # Handle base fatal request error
    # If we have got connection error or whatever
    #   we will fire either Exception or call "if_request_error" if exists
    #
    def handle_request_error_or_return_result
      begin
        @response = EventMachine::HttpRequest.new(url).get(pioneer.http_opts)
      rescue => e
        @error = "Request totaly failed. Url: #{url}, error: #{e.message}"
        pioneer.logger.fatal(@error)
        if pioneer.respond_to? :if_request_error
          return pioneer.if_request_error(self)
        else
          raise Pioneer::HttpRequestError, @error
        end
      end
      handle_response_error_or_return_result
    end

    #
    # Handle http error
    # If we can't make proper response we will ether fire Exception
    #   or call "if_response_error" if exists
    #
    def handle_response_error_or_return_result
      if response.error
        @error = "Response for #{url} get an error: #{response.error}"
        pioneer.logger.error(@error)
        if pioneer.respond_to? :if_response_error
          return pioneer.if_response_error(self)
        else
          raise Pioneer::HttpResponseError, error
        end
      end
      handle_status_or_return_result
    end

    # 
    # Handle wrong status or run "processing"
    # If status is not 200 we will either do nothing (?)
    #   or call "if_status_XXX" if exist
    #   or "if_status_not_200"
    #
    def handle_status_or_return_result
      status = response.response_header.status
      case status
      when 200
        pioneer.processing(self)
      else
        @error = "This #{url} returns this http status: #{status}"
        pioneer.logger.error(@error)
        if pioneer.respond_to? "if_status_#{status}".to_sym
          pioneer.send("if_status_#{status}", self)
        elsif pioneer.respond_to? :if_status_not_200
          pioneer.if_status_not_200(self)
        else
          nil # nothing?
        end
      end
    end

    #
    # We can call retry from crawler like "req.retry"
    # If count is seted, so it will retry it not more then "count" times
    #
    def retry(count=nil)
      if count
        skip if @counter >= count
      end
      raise Pioneer::HttpRetryRequest
    end

    #
    # We can skip request from crawler like "req.skip"
    # I.E. if response_body is blank or 404 error
    #
    def skip
      raise Pioneer::HttpSkipRequest
    end

    #
    # We should parse url befor sending request
    # We use URI.escape for escaping
    # IMPORTAINT: We should replace ampersand (&) in params with "&amp;" !!!
    # Pluses (+) weill be replaced with "%2B"
    #
    def parse_url(url)
      url = "http://" + url unless url =~ /http/
      url = URI.escape(url)
      # replace "&" ampersands :)
      url = url.gsub("&amp;", "%26")
      # replace pluses
      url = url.gsub("+", "%2B")
      url
    end

    #
    # Shortcut for response.response
    #
    def response_body
      response.response
    end

    #
    # Shortcut for response.response_header
    #
    def response_header
      response.response_header
    end
  end
end