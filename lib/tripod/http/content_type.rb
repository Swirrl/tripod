module Tripod
  module Http
    module ContentType
      class << self
        def NTriples;
          'application/n-triples'
        end

        def Turtle
          'text/turtle'
        end

        def JSON;
          'application/json'
        end

        def RDFXml;
          'application/rdf+xml'
        end

        def SPARQLResultsJSON;
          'application/sparql-results+json'
        end

        def SPARQLUpdate;
          'application/sparql-update'
        end
      end
    end
  end
end