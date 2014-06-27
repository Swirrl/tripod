# Copyright (c) 2012 Swirrl IT Limited. http://swirrl.com

# MIT License

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require "tripod/version"

require "active_support/core_ext"
require 'active_support/json'
require "active_support/inflector"
require "active_model"
require "guid"

require 'rdf'
require 'rdf/rdfxml'
require 'rdf/turtle'
require 'rdf/json'
require 'json/ld'
require 'uri'
require 'rest_client'

module Tripod

  mattr_accessor :update_endpoint
  @@update_endpoint = 'http://127.0.0.1:3030/tripod/update'

  mattr_accessor :query_endpoint
  @@query_endpoint = 'http://127.0.0.1:3030/tripod/sparql'

  mattr_accessor :data_endpoint
  @@data_endpoint = 'http://127.0.0.1:3030/tripod/data'

  mattr_accessor :timeout_seconds
  @@timeout_seconds = 30

  mattr_accessor :response_limit_bytes
  @@response_limit_bytes = 5.megabytes

  mattr_accessor :cache_store

  mattr_accessor :logger
  @@logger = Logger.new(STDOUT)
  @@logger.level = Logger::WARN

  # Use +configure+ to override configuration in an app, (defaults shown)
  #
  #   Tripod.configure do |config|
  #     config.update_endpoint = 'http://127.0.0.1:3030/tripod/update'
  #     config.query_endpoint = 'http://127.0.0.1:3030/tripod/sparql'
  #     config.timeout_seconds = 30#
  #     config.response_limit_bytes = 4.megabytes # omit for no limit
  #     config.cache_store = nil #e.g Tripod::CacheStores::MemcachedCacheStore.new('localhost:11211')
  #       # note: if using memcached, make sure you set the -I (slab size) to big enough to store each result
  #       # and set the -m (total size) to something quite big (or the cache will recycle too often).
  #       # also note that the connection pool size can be passed in as an optional second parameter.
  #     config.logger = Logger.new(STDOUT) # you can set this to the Rails.logger in a rails app.
  #   end
  #
  def self.configure
    yield self
  end

end

require 'tripod/cache_stores/memcached_cache_store'

require "tripod/extensions"
require "tripod/streaming"
require "tripod/sparql_client"
require "tripod/sparql_query"
require "tripod/resource_collection"

require "tripod/predicates"
require "tripod/attributes"
require "tripod/callbacks"
require "tripod/validations/is_url"
require "tripod/errors"
require "tripod/repository"
require "tripod/fields"
require "tripod/criteria"
require "tripod/links"
require "tripod/finders"
require "tripod/persistence"
require "tripod/eager_loading"
require "tripod/serialization"
require "tripod/state"
require "tripod/graphs"
require "tripod/version"

# these need to be at the end
require "tripod/components"
require "tripod/resource"

require 'active_support/i18n'
I18n.enforce_available_locales = true
I18n.load_path << File.dirname(__FILE__) + '/tripod/locale/en.yml'
