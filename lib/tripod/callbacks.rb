module Tripod::Callbacks
  extend ActiveSupport::Concern

  included do
    extend ActiveModel::Callbacks
    define_model_callbacks :initialize, :save, :destroy
  end
end