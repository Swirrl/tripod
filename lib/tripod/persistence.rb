# encoding: utf-8

# This module defines behaviour for persisting to the database.
module Tripod::Persistence
  extend ActiveSupport::Concern
  # Save the resource.
  # Note: regardless of whether it's a new_record or not, we always make the
  # db match the contents of this resource's statements.
  #
  # @example Save the resource.
  #   document.save
  #
  # @return [ true, false ] True is success, false if not.
  def save()

    query = "
      DELETE {<#{@uri.to_s}> ?p ?o}
      INSERT {
        #{ @repository.dump(:ntriples) }
      }
      WHERE {
        <#{@uri.to_s}> ?p ?o
      }
    "

    success = Tripod::SparqlClient::Update::update(query)
    @new_record = false if success
    success
  end

  def destroy()

  end

end