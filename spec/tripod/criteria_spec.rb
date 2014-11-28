require "spec_helper"

describe Tripod::Criteria do

  let(:person_criteria) { Person.all }

  let(:resource_criteria) { Resource.all }

  describe "#initialize" do

    it "should set the resource class accessor" do
      person_criteria.resource_class.should == Person
    end

    it "should initialize the extra clauses to a blank array" do
      person_criteria.extra_clauses.should == []
    end

    context "with rdf_type set on the class" do
      it "should initialize the where clauses to include a type restriction" do
        person_criteria.where_clauses.should == ["?uri a <http://example.com/person>", "?uri ?p ?o"]
      end
    end

    context "with no rdf_type set on the class" do
      it "should initialize the where clauses to ?uri ?p ?o" do
        resource_criteria.where_clauses.should == ["?uri ?p ?o"]
      end
    end
  end

  describe "#where" do

    context 'given a string' do
      it "should add the sparql snippet to the where clauses" do
        resource_criteria.where("blah")
        resource_criteria.where_clauses.should == ["?uri ?p ?o", "blah"]
      end

      it "should return an instance of Criteria" do
        resource_criteria.where("blah").class == Tripod::Criteria
      end

      it "should return an instance of Criteria with the where clauses added" do
        resource_criteria.where("blah").where_clauses.should == ["?uri ?p ?o", "blah"]
      end
    end

    context 'given a hash' do
      context 'with a native Ruby value' do
        let(:value) { 'blah' }

        it 'should construct a sparql snippet with the appropriate predicate, treating the value as a literal' do
          criteria = resource_criteria.where(label: value)
          criteria.where_clauses[1].should == "?uri <#{ RDF::RDFS.label }> \"#{ value }\""
        end
      end

      context 'with a native RDF value' do
        let(:value) {  RDF::URI.new('http://example.com/bob') }

        it 'should construct a sparql snippet with the appropriate predicate' do
          criteria = resource_criteria.where(label: value)
          criteria.where_clauses[1].should == "?uri <#{ RDF::RDFS.label }> <#{ value.to_s }>"
        end
      end
    end
  end

  describe "#extras" do

    it "should add the sparql snippet to the extra clauses" do
      resource_criteria.extras("bleh")
      resource_criteria.extra_clauses.should == ["bleh"]
    end

    it "should return an instance of Criteria" do
      resource_criteria.extras("bleh").class == Tripod::Criteria
    end

    it "should return an instance of Criteria with the extra clauses added" do
      resource_criteria.extras("bleh").extra_clauses.should == ["bleh"]
    end
  end

  describe "#limit" do
    it "calls extras with the right limit clause" do
      resource_criteria.limit(10)
      resource_criteria.limit_clause.should == "LIMIT 10"
    end

    context 'calling it twice' do
      it 'should overwrite the previous version' do
         resource_criteria.limit(10)
         resource_criteria.limit(20)
         resource_criteria.limit_clause.should == "LIMIT 20"
      end
    end
  end

  describe "#offset" do
    it "calls extras with the right limit clause" do
      resource_criteria.offset(10)
      resource_criteria.offset_clause.should == "OFFSET 10"
    end

    context 'calling it twice' do
      it 'should overwrite the previous version' do
         resource_criteria.offset(10)
         resource_criteria.offset(30)
         resource_criteria.offset_clause.should == "OFFSET 30"
      end
    end
  end

  describe "#order" do
    it "calls extras with the right limit clause" do
      resource_criteria.order("DESC(?label)")
      resource_criteria.order_clause.should == "ORDER BY DESC(?label)"
    end

    context 'calling it twice' do
      it 'should overwrite the previous version' do
         resource_criteria.order("DESC(?label)")
         resource_criteria.order("ASC(?label)")
         resource_criteria.order_clause.should == "ORDER BY ASC(?label)"
      end
    end
  end

  describe "#graph" do
    it "sets the graph_uri for this criteria, as a string" do
      resource_criteria.graph(RDF::URI("http://example.com/foobar"))
      resource_criteria.graph_uri.should == "http://example.com/foobar"
    end
  end

end
