# encoding: utf-8

# This module defines behaviour for attributes.
module Tripod::Attributes

  extend ActiveSupport::Concern

  # Reads values from this respource's in-memory statement repository, where the predicate matches that of the uri passed in.
  # Returns an Array of RDF::Terms object.
  #
  # @example Read an attribute.
  #   person.read_attribute('http://foo')
  #   person.read_attribute(RDF::URI.new('http://foo'))
  #
  # @example Read an attribute (alternate syntax.)
  #   person['http://foo']
  #   person[RDF::URI.new('http://foo')]
  #
  # @param [ String, RDF::URI ] uri The uri of the attribute to get.
  #
  # @return [ Array ] An array of RDF::Terms.
  def read_attribute(predicate_uri)
    values = []
    @repository.query( [:subject, RDF::URI.new(predicate_uri.to_s), :object] ) do |statement|
      values << statement.object
    end
    values
  end
  alias :[] :read_attribute

  # Replace the statement-values for a single predicate in this resource's in-memory repository.
  #
  # @example Write the attribute.
  #   person.write_attribute('http://title', "Mr.")
  #   person.write_attribute('http://title', ["Mrs.", "Ms."])
  #
  # @example Write the attribute (alternate syntax.)
  #   person['http://title'] = "Mr."
  #   person['http://title'] = ["Mrs.", "Ms."]
  #
  # @param [ String, RDF::URI ] predicate_uri The name of the attribute to update.
  # @param [ Object, Array ] value The values to set for the attribute. Can be an array, or single item. They should compatible with RDF::Terms
  def write_attribute(predicate_uri, objects)
    # remove existing
    remove_attribute(predicate_uri)

    # ... and replace
    objects = [objects] unless objects.kind_of?(Array)
    objects.each do |object|
      @repository << RDF::Statement.new( @uri, RDF::URI.new(predicate_uri.to_s), object )
    end

    # returns the new values
    read_attribute(predicate_uri)
  end
  alias :[]= :write_attribute

  # Append the statement-values for a single predicate in this resource's in-memory repository. Basically just adds a new statement for this ((resource's uri)+predicate)
  #
  # @example Write the attribute.
  #   person.append_attribute('http://title', "Mrs.")
  #   person.append_attribute('http://title', "Ms.")
  #
  # @param [ String, RDF::URI ] predicate_uri The uri of the attribute to update.
  # @param [ Object ] value The values to append for the attribute. Should compatible with RDF::Terms
  def append_to_attribute(predicate_uri, object )
    @repository << RDF::Statement.new(@uri, RDF::URI.new(predicate_uri.to_s), object)
  end
  alias :push :append_to_attribute

  def remove_attribute(predicate_uri)
    @repository.query( [:subject, RDF::URI.new(predicate_uri.to_s), :object] ) do |statement|
      @repository.delete( statement )
    end
  end
  alias :delete :remove_attribute

end