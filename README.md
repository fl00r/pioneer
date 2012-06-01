# Pioneer

Pioneer is a simple async HTTP crawler based on em-synchrony. But it crawls by your rules. You should specify urls to crawl, or specify how to find those urls to crawl.

# Install

```bash
gem install pioneer
```

# Usage

## Basic

Basically you need to define two methods: `locations` and `processing` to create your own crawler.

`locations` method should return any Enumerable, in the simplest case - an Array. `processing` methods accepts `Request` object and should do something with it: save response to file, find new urls to crawl etc.

Let's download few web pages to file (Rayan, I am so sorry!):

```ruby
require 'pioneer'

class Crawler < Pioneer::Base
  def locations
    ["http://railscasts.com/episodes/355-hacking-with-arel", "http://railscasts.com/episodes/354-squeel"]
  end

  def processing(req)
    filename = req.url.split("/").last + ".html"
    File.open(filename, "w+") do |f|
      f << req.response.response
    end
  end
end

Crawler.new.start
```

Ok, we got it: two files 354-squeel.html and 355-hacking-with-arel.html.

## Not so basic

So. There is some standart methods, which you can redefine:

  * locations
  * processing(req)
  * if_request_error(req)
  * if_response_error(req)
  * if_status_not_200(req)
  * if_status_XXX(req) (where XXX is any status you want, for example, `if_status_300`, `if_status_301`)

And few helpers for `Request` object:

  * retry(count)
  * skip

You can call `req.retry` or `req.skip` in any of those `if_xxx` methods:

```ruby
class Crawler < Pioneer::Base
  ...
  def if_request_error(req)
    req.retry
  end

  def if_status_not_200(req)
    req.skip
  end
end
```

You can specify amount of retries in `retry` method: `req.retry(10)`. It means, that after 10 retries crawler will skip this request.

### if_request_error

If, while you are crawling, there is some request error (Internet connection error or something else) crawler will raise an error, or will call your `if_request_error` if defined. You can retry a request, or skip it.

### if_response_error

If server can't handle our request we will get an error. Crawler will fire an Exception or will call `if_response_error` if defined. You can retry a request, or skip it.

### if_response_not_200 or if_response_xxx

Basicaly we need status 200 from request, but we can get redirect status, or page not found or anything else. So you can handle your behaviour in this callback

### Example

```ruby
require 'pioneer'
class Crawler < Pioneer::Base
  def locations
    ["http://www.google.com", "http://www.apple.com/not_found"]
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

Crawler.new.start
#=> I, [2012-06-02T00:53:55.876818 #5099]  INFO -- : going to http://www.google.com
#=> I, [2012-06-02T00:53:55.884415 #5099]  INFO -- : going to http://www.apple.com/not_found
#=> E, [2012-06-02T00:53:55.959504 #5099] ERROR -- : This http://www.google.com returns this http status: 302
#=> E, [2012-06-02T00:53:56.360271 #5099] ERROR -- : This http://www.apple.com/not_found returns this http status: 404
```

**What is `req`?**

req.response id `em-http-request` response object ;)

### Overriding behavior

You can override all methods on the fly:

```ruby
crawler = Pioneer::Crawler.new # base simple crawler
crawler.locations = [url1, url2]
crawler.processing = proc{ req.response.response_header.status }
crawler.if_status_404{ |req| "Oups" }
...
```
## Options

You can pass options to crawler:

```ruby
class Crawler < Pioneer::Base
  def locations ...
  def processung ...
end

crawler = Crawler.new( concurrency: 100, sleep: 0.01, redirects: 2 ... )
```


  * name
    Crawler name (for logs)
  * concurrency
    concurrency level: how many parallel requests will be handled (default 10)
  * sleep
    how log should crawler wait between each request (default 0)
  * log_enabled
    logging is enabled by default
  * log_level
    log level is Logger::DEBUG by default
  * random_header
    crawler can be a copycat of real browser, you need to turn on random_header to get random browser header (false, by default)
  * header
    you can pass your own headers as a hash (cookies i.e.)
  * redirects
    how many redirects can crawler do (0 by default)
  * headers
    you can specify your own headers callback: manual handle redirects or whatever (see em-http-request, headers callback)
  * request_opts
    em-http-request options

.. to be continued