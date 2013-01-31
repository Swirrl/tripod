# encoding: utf-8

# This module defines behaviour for attributes.
module Tripod::Attributes

  extend ActiveSupport::Concern

  def read_attribute(name, field=nil)
    field ||= self.fields[name]
    raise Tripod::Errors::FieldNotPresent.new unless field

    attr_values = read_predicate(field.predicate)
    # We always return strings on way out.
    # If the field is multivalued, return an array of the results
    # If it's not multivalued, return the first (should be only) result.
    if field.multivalued
      attr_values.map do |v|
        v.nil? ? nil : v.to_s
      end
    else
      first_val = attr_values.first
      first_val.nil? ? nil : first_val.to_s
    end
  end
  alias :[] :read_attribute

  def write_attribute(name, value, field=nil)
    field ||= self.fields[name]
    raise Tripod::Errors::FieldNotPresent.new unless field

    if value.kind_of?(Array)
      if field.multivalued
        new_val = []
        value.each do |v|
          new_val << self.class.new_value_for_field(v, field)
        end
      else
        new_val = self.class.new_value_for_field(value.first, field)
      end
    else
      new_val = self.class.new_value_for_field(value, field)
    end

    write_predicate(field.predicate, new_val)
  end
  alias :[]= :write_attribute

  def write_attributes(attrs={})
    attrs.each_pair do |name, value|
      write_attribute(name, value)
    end
  end
end