# Pioneer

Pioneer is a simple async HTTP crawler based on em-synchrony

# Install

```bash
gem install pioneer
```

# Usage

To use `Pioneer` you should specify a class with two methods: `locations` and `processing(req)`.

First one should return enumerable object and second will accept request object.

```ruby
class Crawler << Pioneer::Base
  def locations
    ["http://www.amazon.com", "http://www.apple.com"]
  end

  def processing(req)
    File.open(req.url, "w+") do |f|
      f << req.response.response
    end
  end
end

Crawler.new.start
```

In this example we are saving two files with html of those two sites.

`start` method will start iterating over urls and return an Array of what `processing` method returns.

# Handling request, response errors and statuses

In case of request or response error `Pioneer` will raise an error. Or we can catch them this way:

```ruby
class Crawler << Pioneer::Base
  def locations
    ["http://www.amazon.com", "http://www.apple.com"]
  end

  def processing(req)
    File.open(req.url, "w+") do |f|
      f << req.response.response
    end
  end

  def if_request_error(req)
    puts "Request error: #{req.error}"
  end

  def if_response_error(req)
    puts "Response error: #{req.response.error}"
  end

  def if_status_203(req)
    puts "He is trying to redirect me"
  end
end
```

also you can write `if_status_not_200` to handle all statuses not 200, or `if_status_XXX` for any status you want.

# Overriding behavior

You can override all methods on the fly:

```ruby
crawler = Pioneer::Crawler.new # base simple crawler
crawler.locations = [url1, url2]
crawler.processing = proc{ req.response.response_header.status }
crawler.if_status_404{ |req| "Oups" }
```

As far as `locations` should return Enumerable you can use nested crawlers to save whole site

```ruby
require 'pioneer'
require 'nokogiri'
class Links
  include Enumerable
  def initialize(link)
    @links = [link]
  end

  def <<(link)
    @links << link
  end

  def each
    @links.each{ |url| url }
  end
end

class LinksCrawler < Pioneer::Base
  def locations
    @links = Links.new("http://www.gazeta.ru")
  end

  def processing(req)
    doc = Nokogiri::HTML.parse(req.response.response)
    links = doc.css("a").map{|link| link["href"]} # + some logic to filter links to prevent duplications and another hosts etc
    @links << links
    File.new(req.url, "w+"){ |f| f << req.response.response }
  end
end
LinksCrawler.new(concurrency: 20, redirects: 1, sleep: 0.5).start
```

... to be continued