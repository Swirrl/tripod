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

module Spec
  module Tripod
    module Inheritance
      BASE_PREDICATE = RDF::URI.new("http://base/predicate/overriden/from/SubSub/up")
      BASE_PREDICATE_OVERIDE = RDF::URI.new("http://overide/base/predicate")

      ANOTHER_PREDICATE = RDF::RDFS::label

      class Base
        include ::Tripod::Resource
        field :inherited, BASE_PREDICATE
      end

      class Sub < Base
        field :bar, ANOTHER_PREDICATE
        # expects inerited to be ANOTHER_PREDICATE
      end

      class SubSub < Sub
        field :inherited, BASE_PREDICATE_OVERIDE
      end

      class SubSubSub < SubSub
        # defines no new fields, used to test no NullPointerExceptions
        # etc on classes that don't define fields.
      end

      describe 'inheritance' do
        describe Base do
          subject(:base) { Base }

          it "does not inhert fields from subclasses" do
            expect(base.fields[:bar]).to be_nil
          end

          it "defines the :inherited field" do
            inherited_field = base.fields[:inherited]
            expect(inherited_field.predicate).to eq(BASE_PREDICATE)
          end
        end

        describe Sub do
          subject(:inherited) { Sub.get_field(:inherited) }
          it "does not redefine :inherited field" do
            expect(inherited.predicate).to eq(BASE_PREDICATE)
          end
        end

        describe SubSub do
          subject(:inherited) { SubSub.get_field(:inherited) }

          it "overrides the :inherited field" do
            expect(inherited.predicate).to eq(BASE_PREDICATE_OVERIDE)
          end
        end

        describe SubSubSub do
          it "inherits the :bar field from Sub" do
            bar = SubSubSub.get_field(:bar)
            expect(bar.predicate).to eq(ANOTHER_PREDICATE)
          end

          it "overrides the :inherited field in Base with the value from SubSub" do
            inherited = SubSubSub.get_field(:inherited)
            expect(inherited.predicate).to eq(BASE_PREDICATE_OVERIDE)
          end
        end
      end
    end
  end
end
