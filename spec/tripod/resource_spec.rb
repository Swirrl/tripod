require "spec_helper"

describe Tripod::Resource do

  describe "#initialize" do

    let(:person) do
      Person.new()
    end

    it "initialises an empty repo" do
      person.repository.class.should == RDF::Repository
      person.repository.should be_empty
    end

    context 'uri passed in' do

      context 'graph passed in' do
         let(:person) do
          Person.new('http://foobar', 'http://graph')
        end

        it 'sets the uri instance variable' do
          person.uri.should == RDF::URI.new('http://foobar')
        end

        it 'sets the graph_uri instance variable' do
          person.graph_uri.should == RDF::URI.new('http://graph')
        end
      end

      context 'no graph passed in' do
        let(:person) do
          Person.new('http://foobar')
        end

        it 'sets the uri instance variable' do
          person.uri.should == RDF::URI.new('http://foobar')
        end

        it 'doesn\'t set the graph_uri instance variable' do
          person.graph_uri.should be_nil
        end
      end

    end

    context 'no uri or graph passed in' do

      let(:person) do
        Person.new
      end

      it 'uri and graph should be nil' do
        person.uri.should be_nil
        person.graph_uri.should be_nil
      end
    end

  end


end