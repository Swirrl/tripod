require "spec_helper"

describe Tripod::Fields do

  describe ".field" do

    let(:barry) do
      b = Person.new('http://barry')
      b['http://name'] = 'Barry'
      b['http://alias'] = ['Basildon', 'Baz']
      b['http://age'] = 54
      b['http://importantdates'] = [Date.new(2010,01,01), Date.new(2012,01,01)]
      b
    end

    context "with no options" do

      it "creates a getter for the field, which accesses data for the predicate, returning a single String" do
        barry.name.should == "Barry"
      end

      it "creates a setter for the field, which sets data for the predicate" do
        barry.name = "Basildon"
        barry.name.should == "Basildon"
        barry['http://name'].should == [RDF::Literal.new("Basildon")]
      end

    end

    context "with multivalued option" do

      it "creates a getter for the field, which accesses data for the predicate, returning an array of Strings" do
        barry.aliases.should == ['Basildon', 'Baz']
      end

      it "creates a setter for the field, which sets data for the predicate" do
        barry.aliases = ['Basildon', 'Baz', 'B-man']
        barry.aliases.should == ['Basildon', 'Baz', 'B-man']
        barry['http://alias'].should == [RDF::Literal.new("Basildon"),RDF::Literal.new("Baz"),RDF::Literal.new("B-man")]
      end

      context 'with data type' do

        it "creates a getter for the field, which accesses data for the predicate, returning an array of Strings" do
          barry.important_dates.class.should == Array
          barry.important_dates.should == ["2010-01-01Z", "2012-01-01Z"]
        end

        it "creates a setter for the field, which sets data for the predicate, using the right data type" do
          barry.important_dates = [Date.new(2010,01,02),Date.new(2010,01,03)]
          barry['http://importantdates'] = [ RDF::Literal.new(Date.new(2010,01,02)), RDF::Literal.new(Date.new(2010,01,03)) ]
          barry['http://importantdates'].first.datatype = RDF::XSD.date
        end

      end

    end

    context 'with data type' do

      it "creates a getter for the field, which accesses data for the predicate, returning a single String" do
        barry.age.should == "54"
      end

      it "creates a setter for the field, which sets data for the predicate, using the right data type" do
        barry.age = 57
        barry.age.should == '57'
        barry['http://age'] = [ RDF::Literal.new(57) ]
        barry['http://age'].first.datatype = RDF::XSD.integer
      end

    end

    context 'with no data type specified' do

      it "creates the right kind of literals when setting values." do
        barry.name == 100 # set an integer
        barry['http://name'] = [ RDF::Literal.new(100) ]
        barry['http://name'].first.datatype = RDF::XSD.integer
      end


    end

  end

end