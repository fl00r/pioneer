# encoding: utf-8
module Pioneer
  class UndefinedLocations < RuntimeError; end
  class LocationsNotEnumerable < RuntimeError; end
  class UndefinedProcessing < RuntimeError; end
  class LocationsNotEnumerator < RuntimeError; end
  class HttpRequestError < RuntimeError; end
  class HttpResponseError < RuntimeError; end
  class HttpStatusError < RuntimeError; end
  class HttpRetryRequest < RuntimeError; end

  class Base
    attr_reader :name, :concurrency, :sleep, :log_level, :redirect

    def initialize(opts = {})
      raise UndefinedLocations, "you should specify `locations` method in your `self.class`" unless self.methods.include? :locations
      raise UndefinedProcessing, "you should specify `processing` method in your `self.class`" unless self.methods.include? :processing
      raise LocationsNotEnumerator, "you should specify `locations` to return Enumerator" unless self.locations.methods.include? :each
      @name          = opts[:name]          || "crawler"
      @concurrency   = opts[:concurrency]   || 10
      @sleep         = opts[:sleep]         || 0 # sleep is reversed RPS (1/RPS) - frequency of requests.
      @log_enabled   = opts[:log_enabled]   || true # Logger is enabled by default
      @log_level     = opts[:log_level]     || Logger::DEBUG
      @random_header = opts[:random_header] || false
      @header        = opts[:header]        || nil
      @redirects     = opts[:redirects]     || nil
    end

    def start
      raise LocationsNotEnumerable, "location should respond to `each`" unless locations.respond_to? :each
      result = []
      EM.synchrony do
        # Using FiberPeriodicTimerIterator that implements RPS (request per second feature)
        # In case @sleep is 0 it behaves like standart FiberIterator
        EM::Synchrony::FiberPeriodicTimerIterator.new(locations, concurrency, sleep).map do |url|
          result << Request.new(url, self).perform
        end
        EM.stop
      end
      result
    end

    def logger
      @logger ||= begin
        logger = Logger.new(STDOUT)
        logger.level = log_level
        logger
      end
    end

    def http_opts
      opts = {}
      opts[:head] = random_header if @random_header
      opts[:head] = @header if @header
      opts[:redirects] = @redirects if @redirects
      opts
    end

    def random_header
      HttpHeader.random
    end

    # we should override only our methods: locations, processing, if_XXX
    def method_missing(method_name, *args, &block)
      case method_name
      when /locations.*=|processing.*=|if_.+=/
        method_name = method_name.to_s.gsub("=", "").to_sym
        override_method(method_name, args.first)
      else
        super(method_name, *args, &block)
      end
    end

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