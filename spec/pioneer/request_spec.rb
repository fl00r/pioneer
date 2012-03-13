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
    processing = proc{ |req| req.response_header.status + 1 }
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

  it "should use headers" do
    @crawler1 = KinopoiskCrawler.new(random_header: false)
    @crawler2 = KinopoiskCrawler.new(random_header: false, redirects: 1)
    @crawler3 = KinopoiskCrawler.new(random_header: true)
    # this one will redirect
    @crawler1.start.must_equal [nil]
    # this one will return some restrictions (it need real headres)
    (@crawler2.start.first < 10000).must_equal true
    # and this one will fire up
    (@crawler3.start.first > 10000).must_equal true
  end

  it "should skip url" do
    @result = []
    crawler = Pioneer::Crawler.new(redirects: 1)
    crawler.locations = ["http://not.exist.page.com", "http://amazon.com"]
    crawler.processing = proc{ |req| @result << req.url }
    crawler.if_response_error = proc{ |req| req.skip }
    crawler.start
    @result.must_equal ["http://amazon.com"]
  end

  it "should retry 2 times and skip" do
    @result = []
    @retries = nil
    crawler = Pioneer::Crawler.new(redirects: 1)
    crawler.locations = ["http://not.exist.page.com", "http://amazon.com"]
    crawler.processing = proc{ |req| @result << req.url }
    crawler.if_response_error = proc{ |req| @retries = req.counter; req.retry(2); }
    crawler.start
    @result.must_equal ["http://amazon.com"]
    @retries.must_equal 2
  end
end