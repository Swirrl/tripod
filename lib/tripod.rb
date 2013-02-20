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
require 'rdf/n3'
require 'rdf/json'
require 'json/ld'

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

  # Use +configure+ to override configuration in an app, e.g.:
  #
  #   Tripod.configure do |config|
  #     config.update_endpoint = 'http://127.0.0.1:3030/tripod/update'
  #     config.query_endpoint = 'http://127.0.0.1:3030/tripod/sparql'
  #     config.timeout_seconds = 30
  #   end
  #
  def self.configure
    yield self
  end

end

require "tripod/extensions"
require "tripod/sparql_client"
require "tripod/sparql_query"

require "tripod/predicates"
require "tripod/attributes"
require "tripod/errors"
require "tripod/repository"
require "tripod/fields"
require "tripod/criteria"
require "tripod/finders"
require "tripod/persistence"
require "tripod/eager_loading"
require "tripod/serialization"
require "tripod/state"
require "tripod/version"

# these need to be at the end
require "tripod/components"
require "tripod/resource"