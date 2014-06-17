require "spec_helper"

describe Tripod::SparqlQuery do

  describe '#initialize' do
    context 'given a query without prefixes' do
      it 'should assign the given query to the body attribute' do
        q = Tripod::SparqlQuery.new('SELECT xyz')
        q.body.should == 'SELECT xyz'
      end
    end

    context 'given a query with prefixes' do
      it 'should separate the query into prefixes and body' do
        q = Tripod::SparqlQuery.new('PREFIX e: <http://example.com> SELECT xyz')
        q.prefixes.should == 'PREFIX e: <http://example.com>'
        q.body.should == 'SELECT xyz'
      end
    end

    context 'given a query with a leading space' do
      it 'should successfully split up the query' do
        q = Tripod::SparqlQuery.new(' PREFIX e: <http://example.com> SELECT xyz')
        q.prefixes.should == 'PREFIX e: <http://example.com>'
        q.body.should == 'SELECT xyz'
      end
    end

    context 'given a query with comments' do
      it 'should successfully split up the query' do
        q = Tripod::SparqlQuery.new('PREFIX e: <http://example.com>
SELECT xyz # foo
WHERE abc # bar
# baz'
         )
        q.prefixes.should == 'PREFIX e: <http://example.com>'
        q.body.should == 'SELECT xyz # foo
WHERE abc # bar
# baz'
      end
    end

    context 'given a query with interpolations' do
      it 'should interpolate the query' do
        q = Tripod::SparqlQuery.new('SELECT xyz WHERE %{foo}', foo: 'bar')
        q.query.should == 'SELECT xyz WHERE bar'
      end

      context 'where there are missing interpolation values' do
        it "should raise a 'missing variables' exception" do
          expect { Tripod::SparqlQuery.new('SELECT xyz WHERE %{foo}', {bar: 'baz'}) }.to raise_error(Tripod::SparqlQueryMissingVariables)
        end
      end
    end
  end

  describe "#has_prefixes?" do

    context "for a query with prefixes" do
      it "should return true" do
        q = Tripod::SparqlQuery.new('PREFIX e: <http://example.com> SELECT xyz')
        q.has_prefixes?.should be true
      end
    end

    context "for a query without prefixes" do
      it "should return false" do
        q = Tripod::SparqlQuery.new('SELECT xyz')
        q.has_prefixes?.should be false
      end
    end

  end

  describe "#query_type" do

    it 'should return :select given a SELECT query' do
      q = Tripod::SparqlQuery.new('SELECT xyz')
      q.query_type.should == :select
    end

    it 'should return :construct given a CONSTRUCT query' do
      q = Tripod::SparqlQuery.new('CONSTRUCT <xyz>')
      q.query_type.should == :construct
    end

    it 'should return :construct given a DESCRIBE query' do
      q = Tripod::SparqlQuery.new('DESCRIBE <xyz>')
      q.query_type.should == :describe
    end

    it 'should return :ask given an ASK query' do
      q = Tripod::SparqlQuery.new('ASK <xyz>')
      q.query_type.should == :ask
    end

    it "should return :unknown given an unknown type" do
      q = Tripod::SparqlQuery.new('FOO <xyz>')
      q.query_type.should == :unknown
    end
  end

  describe '#extract_prefixes' do
    it 'should return the prefixes and query body separately' do
      q = Tripod::SparqlQuery.new('PREFIX e: <http://example.com> SELECT xyz')
      p, b = q.extract_prefixes
      p.should == 'PREFIX e: <http://example.com>'
      b.should == 'SELECT xyz'
    end
  end

  describe '#as_count_query_str' do
    context "for non-selects" do
      it "should throw an exception" do
        lambda {
          q = Tripod::SparqlQuery.new('ASK { ?s ?p ?o }')
          q.as_count_query_str
        }.should raise_error(Tripod::SparqlQueryError)
      end
    end

    context "for selects" do
      context 'without prefixes' do
        it "should return a new SparqlQuery with the original query wrapped in a count" do
          q = Tripod::SparqlQuery.new('SELECT ?s WHERE { ?s ?p ?o }')
          q.as_count_query_str.should == 'SELECT (COUNT(*) as ?tripod_count_var) {
  SELECT ?s WHERE { ?s ?p ?o }
}'
        end
      end

      context 'with prefixes' do
        it "should move the prefixes to the start" do
          q = Tripod::SparqlQuery.new('PREFIX e: <http://example.com> SELECT ?s WHERE { ?s ?p ?o }')
          q.as_count_query_str.should == 'PREFIX e: <http://example.com> SELECT (COUNT(*) as ?tripod_count_var) {
  SELECT ?s WHERE { ?s ?p ?o }
}'
        end
      end
    end
  end

  describe "#as_first_query_str" do
    context "for non-selects" do
      it "should throw an exception" do
        lambda {
          q = Tripod::SparqlQuery.new('ASK { ?s ?p ?o }')
          q.as_first_query_str
        }.should raise_error(Tripod::SparqlQueryError)
      end
    end

    context "for selects" do
      context 'without prefixes' do
        it "should return a new SparqlQuery with the original query wrapped in a count" do
          q = Tripod::SparqlQuery.new('SELECT ?s WHERE { ?s ?p ?o }')
          q.as_first_query_str.should == 'SELECT * { SELECT ?s WHERE { ?s ?p ?o } } LIMIT 1'
        end
      end

      context 'with prefixes' do
        it "should move the prefixes to the start" do
          q = Tripod::SparqlQuery.new('PREFIX e: <http://example.com> SELECT ?s WHERE { ?s ?p ?o }')
          q.as_first_query_str.should == 'PREFIX e: <http://example.com> SELECT * { SELECT ?s WHERE { ?s ?p ?o } } LIMIT 1'
        end
      end

    end

  end

end