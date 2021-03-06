# encoding: utf-8
module Pioneer
  class UndefinedLocations < StandardError; end
  class LocationsNotEnumerable < StandardError; end
  class UndefinedProcessing < StandardError; end
  class LocationsNotEnumerator < StandardError; end
  class HttpRequestError < StandardError; end
  class HttpResponseError < StandardError; end
  class HttpStatusError < StandardError; end
  class HttpRetryRequest < StandardError; end
  class HttpSkipRequest < StandardError; end

  class Base
    attr_reader :name, :concurrency, :sleep, :log_level, :redirect, :request_opts

    def initialize(opts = {})
      raise UndefinedLocations, "you should specify `locations` method in your `self.class`" unless self.methods.include? :locations
      raise UndefinedProcessing, "you should specify `processing` method in your `self.class`" unless self.methods.include? :processing
      # raise LocationsNotEnumerator, "you should specify `locations` to return Enumerator" unless self.locations.methods.include? :each
      @name          = opts[:name]          || "crawler"
      @concurrency   = opts[:concurrency]   || 10
      @sleep         = opts[:sleep]         || 0 # sleep is reversed RPS (1/RPS) - frequency of requests.
      @log_enabled   = opts[:log_enabled]   || true # Logger is enabled by default
      @log_level     = opts[:log_level]     || Logger::DEBUG
      @random_header = opts[:random_header] || false
      @header        = opts[:header]        || nil
      @redirects     = opts[:redirects]     || nil
      @headers       = opts[:headers]      #|| nil
      @request_opts  = opts[:request_opts] #|| nil
    end

    #
    # Main method: starting crawling through locations
    # If we catch Pioneer::HttpRetryRequest then we are retrying request
    # And if we catch Pioneer::HttpSkipRequest we just return nothing?
    #
    def start
      result = []
      EM.synchrony do
        EM::Synchrony::FiberIterator.new(locations, concurrency).map do |url|
          counter = 0
          begin
            sleep
            result << Request.new(url, self, counter).perform
          rescue Pioneer::HttpRetryRequest => e
            # return to our loop
            counter += 1
            retry
          rescue Pioneer::HttpSkipRequest => e
            nil # do nothing?
          end
        end
        EM.stop
      end
      result
    end

    #
    # Sleep if the last request was recently (less then timout period)
    #
    def sleep
      @next_start ||= Time.now
      if @sleep > 0
        now = Time.now
        sleep_time = @next_start - Time.now
        sleep_time = 0 if sleep_time < 0
        @next_start = Time.now + sleep_time + @sleep
        EM::Synchrony.sleep(sleep_time) if sleep_time > 0
      end
    end

    #
    # Default Pioneer logger
    #
    def logger
      @logger ||= begin
        logger = Logger.new(STDOUT)
        logger.level = log_level
        logger
      end
    end

    #
    # Set headers, such as redirects, cookies etc
    #
    def http_opts
      opts = {}
      opts[:head] = random_header if @random_header
      opts[:head] = @header if @header
      opts[:redirects] = @redirects if @redirects
      opts
    end

    #
    # EmHttpRequest options
    #
    def request_opts
      opts = {}
      opts = case @request_opts
      when Proc
        @request_opts.call
      else
        @request_opts
      end if @request_opts
      opts
    end

    #
    # Generate random header for request
    #
    def random_header
      HttpHeader.random
    end

    #
    # Headers callback
    #
    def headers
      @headers
    end

    #
    # we should override only our methods: locations, processing, if_XXX
    #
    def method_missing(method_name, *args, &block)
      case method_name
      when /locations.*=|processing.*=|if_.+=/
        method_name = method_name.to_s.gsub("=", "").to_sym
        override_method(method_name, args.first)
      else
        super(method_name, *args, &block)
      end
    end

    # 
    # Overriding methods as singeltons so they are availible only for current instance of crawler
    #
    def override_method(method_name, arg)
      if Proc === arg
        self.define_singleton_method method_name do |req|
          arg.call(req)
        end
      else
        self.define_singleton_method method_name do
          arg
        end
      end
    end
  end
end