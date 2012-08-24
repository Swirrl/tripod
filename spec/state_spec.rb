require "spec_helper"

describe Tripod::State do

  describe "#new_record?" do

    context "when calling new on the resource" do

      let(:person) do
        Person.new
      end

      it "returns true" do
        person.should be_a_new_record
      end
    end

    context "when the object has been saved" do

      let(:person) do
        p = Person.new('http://uri')
        p.save
        p
      end

      it "returns false" do
        person.should_not be_a_new_record
      end
    end
  end

  describe "#persisted?" do

    let(:person) do
      Person.new
    end

    it "delegates to new_record?" do
      person.should_not be_persisted
    end

    context "when the object has been destroyed" do
      before do
        person.save
        person.destroy
      end

      it "returns false"
    end
  end

  describe "destroyed?" do

    let(:person) do
      Person.new
    end

    context "when destroyed is true" do

      before do
        person.destroyed = true
      end

      it "returns true"
    end

    context "when destroyed is false" do

      before do
        person.destroyed = false
      end

      it "returns true"

    end

    context "when destroyed is nil" do

      before do
        person.destroyed = nil
      end

      it "returns false"
    end
  end
end
