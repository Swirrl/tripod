module Tripod
  class SparqlQueryMissingVariables < StandardError
    attr_reader :missing_variables, :expected_variables, :received_variables

    def initialize(missing_variables, expected_variables, received_variables)
      raise ArgumentError.new("Missing parameters should be an array") unless missing_variables.is_a?(Array)
      @missing_variables = missing_variables
      @expected_variables = expected_variables
      @received_variables = received_variables
    end

    def to_s
      "Missing parameters: #{@missing_variables.map(&:to_s).join(', ')}"
    end
  end
end