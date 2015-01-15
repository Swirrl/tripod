module Tripod::RdfType
  extend ActiveSupport::Concern

  included do
    # every instance of a resource has an rdf type field, which is set at the class level
    class_attribute :_RDF_TYPE
  end

  def set_rdf_type
    self.rdf_type = self.class.get_rdf_type if respond_to?(:rdf_type=) && self.class.get_rdf_type
  end

  module ClassMethods
    # makes a "field" on this model called rdf_type
    # and sets a class level _RDF_TYPE variable with the rdf_type passed in.
    def rdf_type(new_rdf_type)
      self._RDF_TYPE = RDF::URI.new(new_rdf_type.to_s)
      field :rdf_type, RDF.type, :multivalued => true, :is_uri => true # things can have more than 1 type and often do
    end

    def get_rdf_type
      self._RDF_TYPE
    end
  end
end
