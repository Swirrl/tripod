module Tripod::Embeds
  extend ActiveSupport::Concern

  included do
    validate :embedded_are_valid
  end

  def get_embeds(name, predicate, opts)
    klass = opts.fetch(:class, name.to_s.classify.constantize)
    Many.new(klass, predicate, self)
  end

  def embedded_are_valid
    self.class.get_embedded.each do |name|
      self.errors.add(name, 'contains an invalid resource') unless self.send(name).all? {|resource| resource.valid? }
    end
  end

  module ClassMethods
    def embeds(name, predicate, opts={})
      re_define_method name do
        get_embeds(name, predicate, opts)
      end

      # use this as a way to get to all the embedded properties for validation
      @_EMBEDDED ||= []
      @_EMBEDDED << name
    end

    def get_embedded
      @_EMBEDDED || []
    end
  end
end
