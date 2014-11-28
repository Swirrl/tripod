require "spec_helper"

describe Tripod::Fields do

  describe ".field" do

    let(:barry) do
      b = Person.new('http://example.com/id/barry')
      b.name = 'Barry'
      b
    end

    it "creates a getter for the field, which accesses data for the predicate, returning a single String" do
      barry.name.should == "Barry"
    end

    it "creates a setter for the field, which sets data for the predicate" do
      barry.name = "Basildon"
      barry.name.should == "Basildon"
    end

    it "creates a check? method, which returns true when the value is present" do
      barry.name?.should == true
    end

    context "when the value is not set" do
      before { barry.name = nil }

      it "should have a check? method which returns false" do
        barry.name?.should == false
      end
    end

    context "given a field of type URI where an invalid URI is given" do
      before { barry.father = 'Steven Notauri' }

      it "should not be valid" do
        barry.should_not be_valid
      end
    end
  end

  describe '.get_field' do
    it 'should raise an error if the field does not exist' do
      expect { Person.send(:get_field, :shoe_size) }.to raise_error(Tripod::Errors::FieldNotPresent)
    end

    it 'should return the field for the given name' do
      Person.send(:get_field, :age).name.should == :age
    end
  end
end
