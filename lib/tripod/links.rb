# encoding: utf-8
require "tripod/links/linked_to"
require "tripod/links/linked_from"

# This module defines behaviour for fields.
module Tripod::Links
  extend ActiveSupport::Concern

  included do
    class_attribute :linked_tos
    class_attribute :linked_froms
    self.linked_tos = {}
    self.linked_froms = {}
  end

  module ClassMethods

    # Define a link to another resource. Creates relevant fields and getter / setter.
    #
    # @example Define a link away from resources of this class to resources of class Organisation
    #   linked_to :organisation, 'http://example.com/name'
    #
    # @example Define a multivalued link away from resources of this class (can be combined with other options)
    #   linked_to :organisations, 'http://example.com/modified_at',  multivalued: true
    #
    # @example Define a link away from resources of this class, specifying the class and the field name that will be generated
    #   linked_to :org, 'http://example.com/modified_at', class_name: 'Organisation', field: my_field
    #
    # @param [ Symbol ] name The name of the link.
    # @param [ String, RDF::URI ] predicate The predicate for the field.
    # @param [ Hash ] options The options to pass to the field.
    #
    # @option options [ String, RDF::URI ] datatype The uri of the datatype for the field (will be used to create an RDF::Literal of the right type on the way in only).
    # @option options [ Boolean ] multivalued Is this a multi-valued field? Default is false.
    # @option options [ String ] class_name The name of the class of resource which we're linking to (normally will derive this from the link name)
    # @option options [ Symbol ] the symbol of the field that will be generated (normally will just add _uri or _uris to the link name)
    #
    # @return [ Field ] The generated field
    def linked_to(name, predicate, options = {})
      add_linked_to(name, predicate, options)
    end


    # Define that another resource links to this one. Creates a getter with the name you specify.
    # For this to work, the incoming class needs to define a linked_to relationship.
    # Just creates the relevant getter which always return an array of objects.
    #
    # @example make a method called people which returns Person objects, via the organisation linked_to field on Person.
    #   linked_from :doggies, :owner, class_name: 'Dog'
    def linked_from(name, incoming_field_name, options = {})
      add_linked_from(name, incoming_field_name, options)
    end

    protected

    def add_linked_to(name, predicate, options={})
      link = linked_to_for(name, predicate, options)
      linked_tos[name] = link

      # create the field (always is_uri)
      add_field(link.field_name, predicate, options.merge(is_uri: true))

      create_linked_to_accessors(name, name)
    end

    def add_linked_from(name, incoming_field_name, options={})
      link = linked_from_for(name, incoming_field_name, options)
      linked_froms[name] = link

      create_linked_from_getter(name, name, link)
    end

    def create_linked_to_accessors(name, meth)
      link = linked_tos[name]

      create_linked_to_getter(name, meth, link)
      create_linked_to_setter(name, meth, link)
    end

    def create_linked_from_getter(name, meth, link)

      generated_methods.module_eval do
        re_define_method(meth) do
          klass = Kernel.const_get(link.class_name)

          incoming_link = klass.linked_tos[link.incoming_field_name.to_sym]
          incoming_predicate = klass.fields[incoming_link.field_name].predicate

          klass
            .where("?uri <#{incoming_predicate.to_s}> <#{self.uri.to_s}>")
            .resources
        end
      end
    end

    def create_linked_to_getter(name, meth, link)

      generated_methods.module_eval do
        re_define_method(meth) do

          klass = Kernel.const_get(link.class_name)

          if link.multivalued?
            # TODO: is there a more efficient way of doing this?
            criteria = klass.where('?uri ?p ?o')
            read_attribute(link.field_name).each do |uri|
              criteria.where("FILTER(?uri = <#{uri.to_s}>)")
            end
            criteria.resources
          else
            klass.find(read_attribute(link.field_name)) rescue nil #look it up by it's uri
          end

        end
      end
    end

    def create_linked_to_setter(name, meth, link)

      generated_methods.module_eval do
        re_define_method("#{meth}=") do |value|

          if link.multivalued?
            value.to_a.each do |r|
              write_attribute( link.field_name, r.uri )
            end
          else
            # set the uri from the passed in resource
            write_attribute( link.field_name, value.uri )
          end
        end
      end
    end

    # instantiates and returns a new LinkedFrom
    def linked_from_for(name, incoming_field_name, options)
      Tripod::Links::LinkedFrom.new(name, incoming_field_name, options)
    end

     # instantiates and returns a new LinkTo
    def linked_to_for(name, predicate, options)
      Tripod::Links::LinkedTo.new(name, predicate, options)
    end

  end

end