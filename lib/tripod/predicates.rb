# encoding: utf-8

# This module defines behaviour for predicates.
module Tripod::Predicates

  extend ActiveSupport::Concern

  # Reads values from this resource's in-memory statement repository, where the predicate matches that of the uri passed in.
  # Returns an Array of RDF::Terms object.
  #
  # @example Read the value associated with a predicate.
  #   person.read_predicate('http://foo')
  #   person.read_predicate(RDF::URI.new('http://foo'))
  #
  # @param [ String, RDF::URI ] uri The uri of the predicate to get.
  #
  # @return [ Array ] An array of RDF::Terms.
  def read_predicate(predicate_uri)
    values = []
    @repository.query( [:subject, RDF::URI.new(predicate_uri.to_s), :object] ) do |statement|
      values << statement.object
    end
    values
  end

  # Replace the statement-values for a single predicate in this resource's in-memory repository.
  #
  # @example Write the predicate.
  #   person.write_predicate('http://title', "Mr.")
  #   person.write_predicate('http://title', ["Mrs.", "Ms."])
  #
  # @param [ String, RDF::URI ] predicate_uri The name of the attribute to update.
  # @param [ Object, Array ] value The values to set for the attribute. Can be an array, or single item. They should be compatible with RDF::Terms
  def write_predicate(predicate_uri, objects)
    # remove existing
    remove_predicate(predicate_uri)

    # ... and replace
    objects = [objects] unless objects.kind_of?(Array)
    objects.each do |object|
      @repository << RDF::Statement.new( @uri, RDF::URI.new(predicate_uri.to_s), object )
    end

    # returns the new values
    read_predicate(predicate_uri)
  end

  # Append the statement-values for a single predicate in this resource's in-memory repository. Basically just adds a new statement for this ((resource's uri)+predicate)
  #
  # @example Write the attribute.
  #   person.append_to_predicate('http://title', "Mrs.")
  #   person.append_to_predicate('http://title', "Ms.")
  #
  # @param [ String, RDF::URI ] predicate_uri The uri of the attribute to update.
  # @param [ Object ] value The values to append for the attribute. Should compatible with RDF::Terms
  def append_to_predicate(predicate_uri, object )
    raise Tripod::Errors::UriNotSet.new() unless @uri

    @repository << RDF::Statement.new(@uri, RDF::URI.new(predicate_uri.to_s), object)
  end

  def remove_predicate(predicate_uri)
    @repository.query( [:subject, RDF::URI.new(predicate_uri.to_s), :object] ) do |statement|
      @repository.delete( statement )
    end
  end
  alias :delete :remove_predicate

end