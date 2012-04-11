# encoding: utf-8
require 'spec_helper'

describe Pioneer::Base do
  before do
  end

  it "should pass request_opts as a proc" do
    request_opts = proc do
      {
        bind: {host: "192.168.1.1", port: '0'}
      }
    end
    @pioneer = Pioneer::Crawler.new(request_opts: request_opts)
    @pioneer.request_opts[:bind][:host].must_equal "192.168.1.1"
  end

  it "should pass request_opts as a Hash" do
    request_opts = begin
      {
        bind: {host: "192.168.1.1", port: '0'}
      }
    end
    @pioneer = Pioneer::Crawler.new(request_opts: request_opts)
    @pioneer.request_opts[:bind][:host].must_equal "192.168.1.1"
  end
end