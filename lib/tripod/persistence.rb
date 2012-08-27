# encoding: utf-8

# This module defines behaviour for persisting to the database.
module Tripod::Persistence
  extend ActiveSupport::Concern
  # Save the resource.
  # Note: regardless of whether it's a new_record or not, we always make the
  # db match the contents of this resource's statements.
  #
  # @example Save the resource.
  #   resource.save
  #
  # @return [ true, false ] True is success, false if not.
  def save()
    if self.valid?
      query = "
        DELETE {GRAPH ?g {<#{@uri.to_s}> ?p ?o}} WHERE {GRAPH ?g {<#{@uri.to_s}> ?p ?o}};
        INSERT DATA {
          GRAPH <#{@graph_uri}> {
            #{ @repository.dump(:ntriples) }
          }
        }
      "
      success = Tripod::SparqlClient::Update::update(query)
      @new_record = false if success
      success
    else
      false
    end
  end

  def destroy()
    query = "
      # delete from default graph:
      DELETE {<#{@uri.to_s}> ?p ?o} WHERE {<#{@uri.to_s}> ?p ?o};
      # delete from named graphs:
      DELETE {GRAPH ?g {<#{@uri.to_s}> ?p ?o}} WHERE {GRAPH ?g {<#{@uri.to_s}> ?p ?o}};
    "
    success = Tripod::SparqlClient::Update::update(query)
    @destroyed = true if success
    success
  end

end