require "spec_helper"

describe Tripod::Criteria do

  let(:person_criteria) do
    c = Person.all #Tripod::Criteria.new(Person)
  end

  let(:resource_criteria) do
    c = Resource.all #Tripod::Criteria.new(Resource)
  end

  let!(:john) do
    p = Person.new('http://john')
    p.name = "John"
    p.save!
    p
  end

  let!(:barry) do
    p = Person.new('http://barry')
    p.name = "Barry"
    p.save!
    p
  end

  describe "#build_select_query" do

    context "for a class with an rdf_type and graph" do
      it "should return a SELECT query based with an rdf type restriction" do
        person_criteria.send(:build_select_query).should == "SELECT DISTINCT ?uri (<http://graph> as ?graph) WHERE { GRAPH <http://graph> { ?uri a <http://person> . ?uri ?p ?o } }"
      end

      context "and extra restrictions" do
        before { person_criteria.where("[pattern]") }

        it "should return a SELECT query with the extra restriction" do
          person_criteria.send(:build_select_query).should == "SELECT DISTINCT ?uri (<http://graph> as ?graph) WHERE { GRAPH <http://graph> { ?uri a <http://person> . ?uri ?p ?o . [pattern] } }"
        end
      end

      context "with an overriden graph" do
        before { person_criteria.graph("http://anothergraph") }

         it "should override the graph in the query" do
          person_criteria.send(:build_select_query).should == "SELECT DISTINCT ?uri (<http://anothergraph> as ?graph) WHERE { GRAPH <http://anothergraph> { ?uri a <http://person> . ?uri ?p ?o } }"
        end
      end
    end

    context "for a class without an rdf_type and graph" do
      it "should return a SELECT query without an rdf_type restriction" do
        resource_criteria.send(:build_select_query).should == "SELECT DISTINCT ?uri ?graph WHERE { GRAPH ?graph { ?uri ?p ?o } }"
      end

      context "and extra restrictions" do
        before { resource_criteria.where("[pattern]") }

        it "should return a SELECT query with the extra restrictions" do
          resource_criteria.send(:build_select_query).should == "SELECT DISTINCT ?uri ?graph WHERE { GRAPH ?graph { ?uri ?p ?o . [pattern] } }"
        end
      end

      context "with a graph set" do
        before { resource_criteria.graph("http://graphy") }

         it "should override the graph in the query" do
          resource_criteria.send(:build_select_query).should == "SELECT DISTINCT ?uri (<http://graphy> as ?graph) WHERE { GRAPH <http://graphy> { ?uri ?p ?o } }"
        end
      end
    end

    context "with extras" do

      before { resource_criteria.where("[pattern]").extras("LIMIT 10").extras("OFFSET 20") }

      it "should add the extras on the end" do
        resource_criteria.send(:build_select_query).should == "SELECT DISTINCT ?uri ?graph WHERE { GRAPH ?graph { ?uri ?p ?o . [pattern] } } LIMIT 10 OFFSET 20"
      end
    end
  end

  describe "#resources" do



    context "with no extra restrictions" do
      it "should return a set of hydrated objects for the type" do
        person_criteria.resources.to_a.should == [john, barry]
      end
    end

    context "with extra restrictions" do

      before { person_criteria.where("?uri <http://name> 'John'") }

      it "should return a set of hydrated objects for the type and restrictions" do
         person_criteria.resources.to_a.should == [john]
      end
    end

  end

  describe "#first" do

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

    it "should return a set of hydrated objects for the criteria" do
      person_criteria.count.should == 2
      person_criteria.where("?uri <http://name> 'John'").count.should ==1
    end

    it "should call Query.select with the 'count sparql'" do
      sparql = Tripod::SparqlQuery.new(person_criteria.send(:build_select_query)).as_count_query_str
      Tripod::SparqlClient::Query.should_receive(:select).with(sparql).and_call_original
      person_criteria.count
    end

    it "should execute the right Sparql" do
      sparql = "SELECT COUNT(*) { SELECT DISTINCT ?uri (<http://graph> as ?graph) WHERE { GRAPH <http://graph> { ?uri a <http://person> . ?uri ?p ?o } }  LIMIT 10 OFFSET 20 }"
      Tripod::SparqlClient::Query.should_receive(:select).with(sparql).and_call_original
      Person.all.limit(10).offset(20).count
    end

  end

  describe "exeuting a chained criteria" do

    let(:chained_criteria) { Person.where("?uri <http://name> ?name").limit(1).offset(0).order("DESC(?name)") }

    it "should run the right Sparql" do
      sparql = "SELECT DISTINCT ?uri (<http://graph> as ?graph) WHERE { GRAPH <http://graph> { ?uri a <http://person> . ?uri <http://name> ?name } } ORDER BY DESC(?name) LIMIT 1 OFFSET 0"
      Tripod::SparqlClient::Query.should_receive(:select).with(sparql).and_call_original
      chained_criteria.resources
    end

    it "should return the right resources" do
      chained_criteria.resources.to_a.should == [john]
    end

    it "should return the right number of resources" do
      chained_criteria.count.should == 1
    end
  end

end