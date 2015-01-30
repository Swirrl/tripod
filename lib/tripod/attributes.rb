# encoding: utf-8

# This module defines behaviour for attributes.
module Tripod::Attributes

  extend ActiveSupport::Concern

  # Reads an attribute from this resource, based on a defined field
  # Returns the value(s) for the named (or given) field
  #
  # @example Read the value associated with a predicate.
  #   class Person
  #     field :name, 'http://name'
  #   end
  #
  #   person.read_attribute(:name)
  #
  # @param [ String ] name The name of the field for which to get the value.
  # @param [ Field ] field An optional Field object
  #
  # @return Native Ruby object (e.g. String, DateTime) or array of them, depending on whether the field is multivalued or not
  def read_attribute(name, field=nil)
    field ||= self.class.get_field(name)

    attr_values = read_predicate(field.predicate)

    if field.multivalued
      # If the field is multivalued, return an array of the results
      # just return the uri or the value of the literal.
      attr_values.map { |v| field.is_uri? ? v :  v.object }
    else
      # If it's not multivalued, return the first (should be only) result.
      if field.is_uri?
        attr_values.first
      else
        # try to get it in english if it's there. (TODO: make it configurable what the default is)
        val = attr_values.select{ |v| v.language == :en }.first || attr_values.first
        val.object if val
      end
    end
  end
  alias :[] :read_attribute

  # Writes an attribute to the resource, based on a defined field
  #
  # @example Write the value associated with a predicate.
  #   class Person
  #     field :name, 'http://name'
  #   end
  #
  #   person.write_attribute(:name, 'Bob')
  #
  # @param [ String ] name The name of the field for which to set the value.
  # @param [ String ] value The value to set it to
  # @param [ Field ] field An optional Field object
  def write_attribute(name, value, field=nil)
    field ||= self.fields[name]
    raise Tripod::Errors::FieldNotPresent.new unless field

    if value.kind_of?(Array)
      if field.multivalued
        new_val = []
        value.each do |v|
          new_val << write_value_for_field(v, field)
        end
      else
        new_val = write_value_for_field(value.first, field)
      end
    else
      new_val = write_value_for_field(value, field)
    end

    attribute_will_change!(name)
    write_predicate(field.predicate, new_val)
  end
  alias :[]= :write_attribute

  private

  def write_value_for_field(value, field)
    return if value.blank?

    if field.is_uri?
      uri = RDF::URI.new(value.to_s.strip)
    elsif field.datatype
      RDF::Literal.new(value, :datatype => field.datatype)
    else
      value
    end
  end
end
