# encoding: utf-8
require "tripod/fields/standard"

# This module defines behaviour for fields.
module Tripod::Fields
  extend ActiveSupport::Concern

  def self.included(base)
    base.instance_eval do
      @fields ||= {}
    end
    base.extend(ClassMethods)
  end

  def fields
    self.class.fields
  end

  module ClassMethods

    # Defines all the fields that are accessible on the Resource
    # For each field that is defined, a getter and setter will be
    # added as an instance method to the Resource.
    #
    # @example Define a field.
    #   field :name, 'http://example.com/name'
    #
    # @example Define a field of a specific RDF type
    #   field :modified_at, 'http://example.com/modified_at', datatype: RDF::XSD.DateTime
    #
    # @example Define a multi-valued field (can be combined with other options)
    #   field :tags, 'http://example.com/tag', multivalued: true
    #
    # @example Define a field containing a URI to another RDF resource
    #   field :knows, 'http://example.com/knows', is_uri: true
    #
    # @param [ Symbol ] name The name of the field.
    # @param [ String, RDF::URI ] predicate The predicate for the field.
    # @param [ Hash ] options The options to pass to the field.
    #
    # @option options [ String, RDF::URI ] datatype The uri of the datatype for the field (will be used to create an RDF::Literal of the right type on the way in only).
    # @option options [ Boolean ] multivalued Is this a multi-valued field? Default is false.
    #
    # @return [ Field ] The generated field
    def field(name, predicate, options = {})
      @fields ||= {}
      add_field(name, predicate, options)
    end

    # Return the field object on a +Resource+ associated with the given name.
    #
    # @example Get the field.
    #   Person.get_field(:name)
    #
    # @param [ Symbol ] name The name of the field.
    def get_field(name)
      @fields ||= {}
      field = fields[name]
      raise Tripod::Errors::FieldNotPresent.new unless field
      field
    end

    # Return all of the fields on a +Resource+ in a manner that
    # respects Ruby's inheritance rules.  i.e. subclass fields should
    # override superclass fields with the same
    def fields
      tripod_superclasses.map { |c| c.instance_variable_get(:@fields) }.reduce do |acc,class_fields|
        class_fields.merge(acc)
      end
    end

    protected

    def tripod_superclasses
      self.ancestors.select { |a| a.class == Class && a.respond_to?(:fields)}
    end

    # Define a field attribute for the +Resource+.
    #
    # @example Set the field.
    #   Person.add_field(:name, 'http://myfield')
    #
    # @param [ Symbol ] name The name of the field.
    # @param [ String, RDF::URI ] predicate The predicate for the field.
    # @param [ Hash ] options The hash of options.
    def add_field(name, predicate, options = {})
      # create a field object and store it in our hash
      field = field_for(name, predicate, options)
      @fields ||= {}
      @fields[name] = field

      # set up the accessors for the fields
      create_accessors(name, name, options)

      # create a URL validation if appropriate
      # (format nabbed from https://gist.github.com/joshuap/948880)
      validates(name, is_url: true) if field.is_uri?

      field
    end

    # Create the field accessors.
    #
    # @example Generate the accessors.
    #   Person.create_accessors(:name, "name")
    #   person.name #=> returns the field
    #   person.name = "" #=> sets the field
    #   person.name? #=> Is the field present?
    #
    # @param [ Symbol ] name The name of the field.
    # @param [ Symbol ] meth The name of the accessor.
    # @param [ Hash ] options The options.
    def create_accessors(name, meth, options = {})
      field = @fields[name]

      create_field_getter(name, meth, field)
      create_field_setter(name, meth, field)
      create_field_check(name, meth, field)

      # from dirty.rb
      create_dirty_methods(name, meth)
    end

    # Create the getter method for the provided field.
    #
    # @example Create the getter.
    #   Model.create_field_getter("name", "name", field)
    #
    # @param [ String ] name The name of the attribute.
    # @param [ String ] meth The name of the method.
    # @param [ Field ] field The field.
    def create_field_getter(name, meth, field)
      generated_methods.module_eval do
        re_define_method(meth) do
          read_attribute(name, field)
        end
      end
    end

    # Create the setter method for the provided field.
    #
    # @example Create the setter.
    #   Model.create_field_setter("name", "name")
    #
    # @param [ String ] name The name of the attribute.
    # @param [ String ] meth The name of the method.
    # @param [ Field ] field The field.
    def create_field_setter(name, meth, field)
      generated_methods.module_eval do
        re_define_method("#{meth}=") do |value|
          write_attribute(name, value, field)
        end
      end
    end

    # Create the check method for the provided field.
    #
    # @example Create the check.
    #   Model.create_field_check("name", "name")
    #
    # @param [ String ] name The name of the attribute.
    # @param [ String ] meth The name of the method.
    def create_field_check(name, meth, field)
      generated_methods.module_eval do
        re_define_method("#{meth}?") do
          attr = read_attribute(name, field)
          attr == true || attr.present?
        end
      end
    end

    # Include the field methods as a module, so they can be overridden.
    #
    # @example Include the fields.
    #   Person.generated_methods
    #
    # @return [ Module ] The module of generated methods.
    def generated_methods
      @generated_methods ||= begin
        mod = Module.new
        include(mod)
        mod
      end
    end


    # instantiates and returns a new standard field
    def field_for(name, predicate, options)
      Tripod::Fields::Standard.new(name, predicate, options)
    end
  end
end
