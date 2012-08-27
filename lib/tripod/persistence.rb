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

  # Save the resource, and raise an exception if it fails.
  # Note: As with save(), regardless of whether it's a new_record or not, we always make the
  # db match the contents of this resource's statements.
  #
  # @example Save the resource.
  #   resource.save
  #
  # @raise [Tripod::Errors::Validations] if invalid
  #
  # @return [ true ] True is success.
  def save!()
    # try to save
    unless self.save()
      # if we get in here, save failed.
      self.class.fail_validate!(self)
      # TODO: similar stuff for callbacks?
    end
    return true
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

  module ClassMethods #:nodoc:

    # Raise an error if validation failed.
    #
    # @example Raise the validation error.
    #   Person.fail_validate!(person)
    #
    # @param [ Resource ] resource The resource to fail.
    def fail_validate!(resource)
      raise Tripod::Errors::Validations.new(resource)
    end

  end

end