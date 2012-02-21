# encoding: utf-8
require 'spec_helper'
require 'yajl'
# 
# TODO:
# Rewrite real live examples with StubServer
#

describe Pioneer::Request do
  before do
    @pioneer1 = CustomCrawler1.new(name: "Custom crawler 1")
    @pioneer2 = Pioneer::Crawler.new(name: "Base crawler 2")
    @pioneer3 = Pioneer::Crawler.new(name: "Base crawler 3")
  end

  it "should return two 200 response statuses" do
    @pioneer1.start.must_equal [200, 200]
  end

  it "should redefine methods" do
    processing = proc{ |req| req.response.response_header.status + 1 }
    @pioneer2.processing = processing
    @pioneer2.locations = ["www.apple.com", "www.amazon.com"]
    @pioneer2.start.must_equal [201, 201]
    @pioneer2.locations = ["www.ru.erro"]
    if_response_error = proc{ |req| "fail" }
    @pioneer2.if_response_error = if_response_error
    @pioneer2.start.must_equal ["fail"]
  end

  it "should execute if_status_xxx" do
    redirector = proc{ |req| "redirected" }
    error404 = proc{ |req| "notfound" }
    @pioneer2.locations = ["google.com/redirectmeplease", "http://www.amazon.com/notfoundpage"]
    @pioneer2.if_status_301 = redirector
    @pioneer2.if_status_404 = error404
    @pioneer2.start.must_equal ["redirected", "notfound"]
  end

  it "should execute if_status_not_200 if another colback is not defined" do
    not_200 = proc{ "something goes wrong" }
    redirector = proc{ |req| "redirected" }
    @pioneer3.locations = ["google.com/redirectmeplease", "http://www.amazon.com/notfoundpage"]
    @pioneer3.if_status_301 = redirector
    @pioneer3.if_status_not_200 = not_200
    @pioneer3.start.must_equal ["redirected", "something goes wrong"]
  end

  # LAST FM API TEST
  it "should return similar artists for a number of them" do
    @lastfm_pioneer = LastfmCrawler.new(sleep: 0.25)
    @lastfm_pioneer.start.sort.must_equal LastfmEnum.const_get(:ARTISTS).sort
  end
end