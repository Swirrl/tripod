module Tripod::Embeds
  extend ActiveSupport::Concern

  included do
    validate :embedded_are_valid
  end

  def get_embeds(name, predicate, opts)
    klass = opts.fetch(:class, nil)
    klass ||= (self.class.name.deconstantize + '::' + name.to_s.classify).constantize
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

      # add statements to our hydrate query so the repository is populated appropriately
      append_to_hydrate_construct ->(u) { "#{ u } <#{ predicate.to_s }> ?es . ?es ?ep ?eo ." }
      append_to_hydrate_where ->(u) { "OPTIONAL { #{ u } <#{ predicate.to_s }> ?es . ?es ?ep ?eo . }" }
    end

    def get_embedded
      @_EMBEDDED || []
    end
  end
end
