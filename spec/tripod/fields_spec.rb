require "spec_helper"

describe Tripod::Fields do

  describe ".field" do

    let(:barry) do
      b = Person.new('http://barry')
      b.name = 'Barry'
      b
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
      before do
        barry.name = nil
      end

      it "should have a check? method which returns false" do
        barry.name?.should == false
      end
    end
  end
end