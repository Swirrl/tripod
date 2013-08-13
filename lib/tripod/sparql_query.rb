# encoding: utf-8
module Tripod

  class SparqlQueryError < StandardError; end

  class SparqlQuery

    attr_reader :query # the original query string
    attr_reader :query_type # symbol representing the type (:select, :ask etc)
    attr_reader :body # the body of the query
    attr_reader :prefixes # any prefixes the query may have

    cattr_accessor :PREFIX_KEYWORDS
    @@PREFIX_KEYWORDS = %w(BASE PREFIX)
    cattr_accessor :KEYWORDS
    @@KEYWORDS = %w(CONSTRUCT ASK DESCRIBE SELECT)

    def initialize(query_string, interpolations=nil)
      query_string.strip!
      @query = interpolate_query(query_string, interpolations) if interpolations
      @query ||= query_string

      if self.has_prefixes?
        @prefixes, @body = self.extract_prefixes
      else
        @body = self.query
      end

      @query_type = get_query_type
    end

    def has_prefixes?
      self.class.PREFIX_KEYWORDS.each do |k|
        return true if /^#{k}/i.match(query)
      end
      return false
    end

    def extract_prefixes
      i = self.class.KEYWORDS.map {|k| self.query.index(/#{k}/i) || self.query.size+1 }.min
      p = query[0..i-1]
      b = query[i..-1]
      return p.strip, b.strip
    end

    def check_subqueryable!
      # only allow for selects
      raise SparqlQueryError.new("Can't turn this into a subquery") unless self.query_type == :select
    end

    def as_count_query_str
      check_subqueryable!

      count_query = "SELECT (COUNT(*) as ?tripod_count_var) {
  #{self.body}
}"
      count_query = "#{self.prefixes} #{count_query}" if self.prefixes

      # just returns the string representing the count query for this query.
      count_query
    end

    def as_first_query_str
      check_subqueryable!

      first_query = "SELECT * { #{self.body} } LIMIT 1"
      first_query = "#{self.prefixes} #{first_query}" if self.prefixes

      # just returns the string representing the 'first' query for this query.
      first_query
    end

    def self.get_expected_variables(query_string)
      query_string.scan(/[.]?\%\{(\w+)\}[.]?/).flatten.uniq.map(&:to_sym)
    end

    private

    def interpolate_query(query_string, interpolations)
      expected_variables = self.class.get_expected_variables(query_string)
      missing_variables = expected_variables - interpolations.keys

      if missing_variables.any?
        raise SparqlQueryMissingVariables.new(missing_variables, expected_variables, interpolations)
      end

      query_string % interpolations # do the interpolating
    end

    def get_query_type
      if /^CONSTRUCT/i.match(self.body)
        :construct
      elsif /^ASK/i.match(self.body)
        :ask
      elsif /^DESCRIBE/i.match(self.body)
        :describe
      elsif /^SELECT/i.match(self.body)
        :select
      else
        :unknown
      end
    end


  end

end