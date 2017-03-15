$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

MODELS = File.join(File.dirname(__FILE__), "app/models")
$LOAD_PATH.unshift(MODELS)

require 'tripod'
require 'rspec'
require 'webmock/rspec'
require 'binding_of_caller'
require 'pry'

RSpec.configure do |config|
  config.mock_with :rspec

  config.before(:each) do
    WebMock.disable!
    # delete from all graphs.
    # delete from default graph:
    # Tripod::SparqlClient::Update.update('
    #   DELETE {?s ?p ?o} WHERE {?s ?p ?o}')
    #   # delete from named graphs:
    # Tripod::SparqlClient::Update.update('
    #   DELETE {graph ?g {?s ?p ?o}} WHERE {graph ?g {?s ?p ?o}};
    # ')
    Tripod::SparqlClient::Update.update('drop default')
    Tripod::SparqlClient::Update.update('drop all')
  end

end

# configure any settings for testing...
Tripod.configure do |config|
  config.update_endpoint = 'http://127.0.0.1:3030/tripod-test/update'
  config.query_endpoint = 'http://127.0.0.1:3030/tripod-test/sparql'
  config.data_endpoint = 'http://127.0.0.1:3030/tripod-test/data'

  # config.update_endpoint = 'http://localhost:5820/test/update'
  # config.query_endpoint = 'http://localhost:5820/test/query'
  #config.data_endpoint = 'http://127.0.0.1:3030/tripod-test/data'
end

# Autoload every model for the test suite that sits in spec/app/models.
Dir[ File.join(MODELS, "*.rb") ].sort.each do |file|
  name = File.basename(file, ".rb")
  autoload name.camelize.to_sym, name
end
