require "spec_helper"

describe Tripod::Criteria do

  let(:person_criteria) do
    c = Person.all #Tripod::Criteria.new(Person)
  end

  let(:resource_criteria) do
    c = Resource.all #Tripod::Criteria.new(Resource)
  end

  let!(:john) do
    p = Person.new('http://example.com/id/john')
    p.name = "John"
    p.save!
    p
  end

  let!(:barry) do
    p = Person.new('http://example.com/id/barry')
    p.name = "Barry"
    p.save!
    p
  end

  describe "#as_query" do

    context "when graph_lambdas exist" do
      it "should return the contents of the block inside a graph statement with unbound ?g parameter" do
        resource_criteria.graph(nil) do
          "?uri ?p ?o"
        end
        resource_criteria.as_query.should == "SELECT DISTINCT ?uri WHERE { GRAPH ?g { ?uri ?p ?o } ?uri ?p ?o }"
      end

      it "should be possible to bind to the ?g paramter on the criteria after supplying a block" do
        resource_criteria.graph(nil) do
          "?uri ?p ?o"
        end.where("?uri ?p ?g")
        resource_criteria.as_query.should == "SELECT DISTINCT ?uri WHERE { GRAPH ?g { ?uri ?p ?o } ?uri ?p ?g }"
      end
    end

    context "for a class with an rdf_type and graph" do
      it "should return a SELECT query based with an rdf type restriction" do
        person_criteria.as_query.should == "SELECT DISTINCT ?uri (<http://example.com/graph> as ?graph) WHERE { GRAPH <http://example.com/graph> { ?uri a <http://example.com/person> } }"
      end

      context "with include_graph option set to false" do
        it "should not select graphs, but restrict to graph" do
          person_criteria.as_query(:return_graph => false).should == "SELECT DISTINCT ?uri WHERE { GRAPH <http://example.com/graph> { ?uri a <http://example.com/person> } }"
        end
      end

      context "and extra restrictions" do
        before { person_criteria.where("[pattern]") }

        it "should return a SELECT query with the extra restriction" do
          person_criteria.as_query.should == "SELECT DISTINCT ?uri (<http://example.com/graph> as ?graph) WHERE { GRAPH <http://example.com/graph> { ?uri a <http://example.com/person> . [pattern] } }"
        end
      end

      context "with an overriden graph" do
        before { person_criteria.graph("http://example.com/anothergraph") }

         it "should override the graph in the query" do
          person_criteria.as_query.should == "SELECT DISTINCT ?uri (<http://example.com/anothergraph> as ?graph) WHERE { GRAPH <http://example.com/anothergraph> { ?uri a <http://example.com/person> } }"
        end
      end
    end

    context "for a class without an rdf_type and graph" do
      it "should return a SELECT query without an rdf_type restriction" do
        resource_criteria.as_query.should == "SELECT DISTINCT ?uri ?graph WHERE { GRAPH ?graph { ?uri ?p ?o } }"
      end

      context "with include_graph option set to false" do
        it "should not select graphs or restrict to graph" do
          resource_criteria.as_query(:return_graph => false).should ==  "SELECT DISTINCT ?uri WHERE { ?uri ?p ?o }"
        end
      end

      context "and extra restrictions" do
        before { resource_criteria.where("?uri a <http://type>") }

        it "should return a SELECT query with the extra restrictions" do
          resource_criteria.as_query.should == "SELECT DISTINCT ?uri ?graph WHERE { GRAPH ?graph { ?uri a <http://type> } }"
        end
      end

      context "with a graph set" do
        before { resource_criteria.graph("http://example.com/graphy") }

         it "should override the graph in the query" do
          resource_criteria.as_query.should == "SELECT DISTINCT ?uri (<http://example.com/graphy> as ?graph) WHERE { GRAPH <http://example.com/graphy> { ?uri ?p ?o } }"
        end
      end
    end

    context "with extras" do

      before { resource_criteria.where("?uri a <http://type>").extras("LIMIT 10").extras("OFFSET 20") }

      it "should add the extras on the end" do
        resource_criteria.as_query.should == "SELECT DISTINCT ?uri ?graph WHERE { GRAPH ?graph { ?uri a <http://type> } } LIMIT 10 OFFSET 20"
      end
    end
  end

  describe "#resources" do

    context "with options passed" do
      it "should pass the options to as_query" do
        person_criteria.should_receive(:as_query).with(:return_graph => false).and_call_original
        person_criteria.resources(:return_graph => false)
      end
    end

    context "with no extra restrictions" do
      it "should return a set of hydrated objects for the type" do
        person_criteria.resources.to_a.should == [john, barry]
      end
    end

    context "with extra restrictions" do
      before { person_criteria.where("?uri <http://example.com/name> 'John'") }

      it "should return a set of hydrated objects for the type and restrictions" do
        person_criteria.resources.to_a.should == [john]
      end
    end

    context "with return_graph option set to false" do

      context "where the class has a graph_uri set" do
        it "should set the graph_uri on the hydrated objects" do
          person_criteria.resources(:return_graph => false).first.graph_uri.should_not be_nil
        end
      end

      context "where the class does not have a graph_uri set" do
        it "should not set the graph_uri on the hydrated objects" do
          resource_criteria.resources(:return_graph => false).first.graph_uri.should be_nil
        end
      end

    end

  end

  describe "#first" do

    context "with options passed" do
      it "should pass the options to as_query" do
        person_criteria.should_receive(:as_query).with(:return_graph => false).and_call_original
        person_criteria.first(:return_graph => false)
      end
    end

    it "should return the first resource for the criteria" do
      person_criteria.first.should == john
    end

    it "should call Query.select with the 'first sparql'" do
      sparql = Tripod::SparqlQuery.new(person_criteria.as_query).as_first_query_str
      Tripod::SparqlClient::Query.should_receive(:select).with(sparql).and_call_original
      person_criteria.first
    end

    context "with return_graph option set to false" do

      context "where the class has a graph_uri set" do
        it "should set the graph_uri on the hydrated object" do
          person_criteria.first(:return_graph => false).graph_uri.should_not be_nil
        end
      end

      context "where the class does not have a graph_uri set" do
        it "should not set the graph_uri on the hydrated object" do
          resource_criteria.first(:return_graph => false).graph_uri.should be_nil
        end
      end

    end
  end

  describe "#count" do

    context "with options passed" do
      it "should pass the options to as_querys" do
        person_criteria.should_receive(:as_query).with(:return_graph => false).and_call_original
        person_criteria.count(:return_graph => false)
      end
    end

    it "should return a set of hydrated objects for the criteria" do
      person_criteria.count.should == 2
      person_criteria.where("?uri <http://example.com/name> 'John'").count.should ==1
    end

    it "should call Query.select with the 'count sparql'" do
      sparql = Tripod::SparqlQuery.new(person_criteria.as_query).as_count_query_str
      Tripod::SparqlClient::Query.should_receive(:select).with(sparql).and_call_original
      person_criteria.count
    end

    it "should execute the right Sparql" do
      sparql = "SELECT (COUNT(*) as ?tripod_count_var) {
  SELECT DISTINCT ?uri (<http://example.com/graph> as ?graph) WHERE { GRAPH <http://example.com/graph> { ?uri a <http://example.com/person> } }  LIMIT 10 OFFSET 20
}"
      Tripod::SparqlClient::Query.should_receive(:select).with(sparql).and_call_original
      Person.all.limit(10).offset(20).count
    end

  end

  describe "exeuting a chained criteria" do

    let(:chained_criteria) { Person.where("?uri <http://example.com/name> ?name").limit(1).offset(0).order("DESC(?name)") }

    it "should run the right Sparql" do
      sparql = "SELECT DISTINCT ?uri (<http://example.com/graph> as ?graph) WHERE { GRAPH <http://example.com/graph> { ?uri a <http://example.com/person> . ?uri <http://example.com/name> ?name } } ORDER BY DESC(?name) LIMIT 1 OFFSET 0"
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