module Tripod::Validations
  class IsUrlValidator < ActiveModel::EachValidator
    def validate_each(resource, attribute, value)
      return unless value # nil values get passed over.
      is_valid = value.is_a?(Array) ? value.all?{|v| is_url?(v)} : is_url?(value)
      resource.errors.add(attribute, :is_url, options) unless is_valid
    end

    private

    def is_url?(value)
      uri = nil
      begin
        uri = URI.parse(value.to_s)
      rescue
        return false
      end
      return false unless ['http', 'https'].include?(uri.scheme)
      return false unless uri.host.split('.').length > 1
      true
    end
  end
end