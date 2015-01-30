module Tripod::Dirty
  extend ActiveSupport::Concern

  def changed_attributes
    @changed_attributes ||= {}
  end

  def changed
    changed_attributes.keys
  end

  def changes
    changed.reduce({}) do |memo, attr|
      change = attribute_change(attr)
      memo[attr] = change if change
      memo
    end
  end

  def attribute_will_change!(attr)
    changed_attributes[attr] = read_attribute(attr) unless changed_attributes.has_key?(attr)
  end

  def attribute_change(attr)
    [ changed_attributes[attr], read_attribute(attr) ] if attribute_changed?(attr)
  end

  def attribute_changed?(attr)
    return false unless changed_attributes.has_key?(attr)
    (changed_attributes[attr] != read_attribute(attr))
  end

  def post_persist
    changed_attributes.clear
  end

  module ClassMethods
    def create_dirty_methods(name, meth)
      create_dirty_change_check(name, meth)
      create_dirty_change_accessor(name, meth)
      create_dirty_was_accessor(name, meth)
    end

    def create_dirty_change_accessor(name, meth)
      generated_methods.module_eval do
        re_define_method("#{meth}_change") do
          attribute_change(name)
        end
      end
    end

    def create_dirty_change_check(name, meth)
      generated_methods.module_eval do
        re_define_method("#{meth}_changed?") do
          attribute_changed?(name)
        end
      end
    end

    def create_dirty_was_accessor(name, meth)
      generated_methods.module_eval do
        re_define_method("#{meth}_was") do
          changed_attributes[name]
        end
      end
    end
  end
end
