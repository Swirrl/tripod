# encoding: utf-8

# All modules that a +Resource+ is composed of are defined in this
# module, to keep the resource module from getting too cluttered.
module Tripod::Components
  extend ActiveSupport::Concern

  included do
  end

  include ActiveModel::Conversion # to_param, to_key etc.
  # include ActiveModel::MassAssignmentSecurity
  include ActiveModel::Naming
  include ActiveModel::Validations

  include Tripod::Predicates
  include Tripod::Attributes
  include Tripod::Callbacks
  include Tripod::Validations
  include Tripod::Persistence
  include Tripod::Fields
  include Tripod::Links
  include Tripod::Finders
  include Tripod::Repository
  include Tripod::EagerLoading
  include Tripod::Serialization
  include Tripod::State

end