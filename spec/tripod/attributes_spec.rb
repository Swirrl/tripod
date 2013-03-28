require "spec_helper"

describe Tripod::Attributes do
  describe ".read_attribute" do

    let!(:other_person) do
      p = Person.new('http://example.com/id/garry')
      p.save!
      p
    end

    let(:person) do
      p = Person.new('http://example.com/id/barry')
      p.name = 'Barry'
      p.father = other_person.uri
      p
    end

    context "for a literal" do
      it "should return the native type" do
        person[:name].class.should == String
      end
      it "should read the given attribute" do
        person[:name].should == 'Barry'
      end
    end

    context "for a uri" do
      it "should return an RDF::URI" do
        person[:father].class.should == RDF::URI
      end

      it "should read the given attribute" do
        person[:father].should == other_person.uri
      end
    end

    context "where the attribute is multi-valued" do
      before do
        person.aliases = ['Boz', 'Baz', 'Bez']
      end

      it "should return an array" do
        person[:aliases].should == ['Boz', 'Baz', 'Bez']
      end
    end

    context "where field is given and single-valued" do
      let(:field) { Person.send(:field_for, :hat_type, 'http://example.com/hat', {}) }
      before do
        person.stub(:read_predicate).with('http://example.com/hat').and_return([RDF::Literal.new('fez')])
      end

      it "should use the predicate name from the given field" do
        person.should_receive(:read_predicate).with('http://example.com/hat').and_return([RDF::Literal.new('fez')])
        person.read_attribute(:hat_type, field)
      end

      it "should return a single value" do
        person.read_attribute(:hat_type, field).should == 'fez'
      end
    end

    context "where field is given and is multi-valued" do
      let(:field) { Person.send(:field_for, :hat_types, 'http://example.com/hat', {multivalued: true}) }
      before do
        person.stub(:read_predicate).with('http://example.com/hat').and_return([RDF::Literal.new('fez'), RDF::Literal.new('bowler')])
      end

      it "should return an array of values" do
        person.read_attribute(:hat_types, field).should == ['fez', 'bowler']
      end
    end

    context "where there is no field with the given name" do
      it "should raise a 'field not present' error" do
        lambda { person.read_attribute(:hoof_size) }.should raise_error(Tripod::Errors::FieldNotPresent)
      end
    end
  end

  describe ".write_attribute" do
    let(:person) { Person.new('http://example.com/id/barry') }

    it "should write the given attribute" do
      person[:name] = 'Barry'
      person.name.should == 'Barry'
    end

    it "should co-erce the value given to the correct datatype" do
      person[:age] = 34
      person.read_predicate('http://example.com/age').first.datatype.should == RDF::XSD.integer
    end

    context "where the attribute is a uri" do
      it "should convert a string to an RDF::URI" do
        person[:father] = 'http://example.com/darth'
        person.read_predicate('http://example.com/father').first.should be_a(RDF::URI)
      end
    end

    context "where the attribute is multi-valued" do
      it "should co-erce all the values to the correct datatype" do
        person[:important_dates] = [Date.today]
        person.read_predicate('http://example.com/importantdates').first.datatype.should == RDF::XSD.date
      end
    end

    context "where field is given" do
      let(:field) { Person.send(:field_for, :hat_type, 'http://example.com/hat', {}) }

      it "should derive the predicate name from the given field" do
        person.write_attribute(:hat_type, 'http://example.com/bowlerhat', field)
        person.read_predicate('http://example.com/hat').first.to_s.should == 'http://example.com/bowlerhat'
      end
    end

    context "where a field of a particular datatype is given" do
      let(:field) { Person.send(:field_for, :hat_size, 'http://example.com/hatsize', {datatype: RDF::XSD.integer}) }

      it "should derive the datatype from the given field" do
        person.write_attribute(:hat_size, 10, field)
        person.read_predicate('http://example.com/hatsize').first.datatype.should == RDF::XSD.integer
      end
    end

    context "where a multi-valued field of a given datatype is given" do
      let(:field) { Person.send(:field_for, :hat_heights, 'http://example.com/hatheight', {datatype: RDF::XSD.integer, multivalued: true}) }

      it "should co-erce the values passed" do
        person.write_attribute(:hat_heights, [5, 10, 15], field)
        person.read_predicate('http://example.com/hatheight').first.datatype.should == RDF::XSD.integer
      end
    end

    context "where there is no field with the given name" do
      it "should raise a 'field not present' error" do
        lambda { person.write_attribute(:hoof_size, 'A1') }.should raise_error(Tripod::Errors::FieldNotPresent)
      end
    end
  end
end