require 'pioneer'
require 'minitest/spec'
require 'minitest/autorun'
require 'nokogiri'

# saving two pages
class CustomCrawler1 < Pioneer::Base
  def locations
    ["http://www.ru", "http://www.ru"]
  end

  def processing(req)
    req.response.response_header.status
  end
end

# LastFM test
class LastfmEnum
  include Enumerable

  ARTISTS = ["Cher", "Madonna", "Rolling Stones", "The Beatles", "Muse"]

  def each
    ARTISTS.each do |artist|
      p artist
      url = "http://ws.audioscrobbler.com/2.0/?method=artist.getsimilar&artist=#{artist}&api_key=b25b959554ed76058ac220b7b2e0a026&format=json"
      yield url
    end
  end
end

class LastfmCrawler < Pioneer::Base
  def locations
    LastfmEnum.new
  end

  def processing(req)
    json = Yajl::Parser.parse(req.response.response)
    json["similarartists"]["@attr"]["artist"]
  end
end