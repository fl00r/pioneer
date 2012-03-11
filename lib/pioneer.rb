# Eventmachine
require "em-synchrony"
require "em-synchrony/em-http"
require "em-synchrony/fiber_iterator"
# patch - to remove! maybe pull to em-synchrony?
require "patch/iterator"
# other
require "logger"
require 'uri'
# Code
require "pioneer/version"
require "pioneer/base"
require "pioneer/request"
require "pioneer/http_header"
require "pioneer/crawler"
