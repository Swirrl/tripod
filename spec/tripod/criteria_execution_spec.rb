require "spec_helper"

describe Tripod::Criteria do

  let(:person_criteria) do
    c = Tripod::Criteria.new(Person)
  end

  let(:resource_criteria) do
    c = Tripod::Criteria.new(Resource)
  end

  let(:john) do
    p = Person.new('http://john', 'http://people')
    p.name = "John"
    p
  end

  let(:barry) do
    p = Person.new('http://barry', 'http://people')
    p.name = "Barry"
    p
  end

  describe "#build_select_query" do

    context "for a class with an rdf_type" do
      it "should return a SELECT query based with an rdf type restriction" do
        person_criteria.send(:build_select_query).should == "SELECT ?uri ?graph WHERE { GRAPH ?graph { ?uri a <http://person> } }"
      end

      context "and extra restrictions" do
        before { person_criteria.where("[pattern]") }

        it "should return a SELECT query with the extra restriction and rdf type restriction" do
          person_criteria.send(:build_select_query).should == "SELECT ?uri ?graph WHERE { GRAPH ?graph { ?uri a <http://person> . [pattern] } }"
        end
      end
    end

    context "for a class without an rdf_type" do
      it "should return a SELECT query without an rdf_type restriction" do
        resource_criteria.send(:build_select_query).should == "SELECT ?uri ?graph WHERE { GRAPH ?graph { ?uri ?p ?o } }"
      end

      context "and extra restrictions" do
        before { resource_criteria.where("[pattern]") }

        it "should return a SELECT query with the extra restrictions" do
          resource_criteria.send(:build_select_query).should == "SELECT ?uri ?graph WHERE { GRAPH ?graph { ?uri ?p ?o . [pattern] } }"
        end
      end
    end
  end

  describe "#resources" do

    before do
      john.save!
      barry.save!
    end

    context "with no extra restrictions" do
      it "should return a set of hydrated objects for the type" do
        person_criteria.resources.should == [john, barry]
      end
    end

    context "with extra restrictions" do

      before { person_criteria.where("?uri <http://name> 'John'") }

      it "should return a set of hydrated objects for the type and restrictions" do
         person_criteria.resources.should == [john]
      end
    end

  end

  describe "#first" do

    before do
      john.save!
      barry.save!
    end

    it "should return the first resource for the criteria" do
      person_criteria.first.should == john
    end

    it "should call Query.select with the 'first sparql'" do
      sparql = Tripod::SparqlQuery.new(person_criteria.send(:build_select_query)).as_first_query_str
      Tripod::SparqlClient::Query.should_receive(:select).with(sparql).and_call_original
      person_criteria.first
    end
  end

  describe "#count" do

    before do
      john.save!
      barry.save!
    end

    it "should return a set of hydrated objects for the criteria" do
      person_criteria.count.should == 2
      person_criteria.where("?uri <http://name> 'John'").count.should ==1
    end

    it "should call Query.select with the 'count sparql'" do
      sparql = Tripod::SparqlQuery.new(person_criteria.send(:build_select_query)).as_count_query_str
      Tripod::SparqlClient::Query.should_receive(:select).with(sparql).and_call_original
      person_criteria.count
    end

  end

end