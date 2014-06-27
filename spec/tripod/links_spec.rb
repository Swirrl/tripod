require "spec_helper"

describe Tripod::Links do

  let(:barry) do
    b = Person.new('http://example.com/id/barry')
    b.name = 'Barry'
    b.save!
    b
  end

  let(:gary) do
    g = Person.new('http://example.com/id/gary')
    g.name = 'Gary'
    g.save!
    g
  end

  let(:jonno) do
    j = Person.new('http://example.com/id/jonno')
    j.name = 'Jonno'
    j.save!
    j
  end

  let(:fido) do
    d = Dog.new('http://example.com/id/fido')
    d.name = "fido"
    d.save!
    d
  end

  let!(:spot) do
    d = Dog.new('http://example.com/id/spot')
    d.name = "spot"
    d.owner = barry
    d.save!
    d
  end

  let!(:rover) do
    d = Dog.new('http://example.com/id/rover')
    d.name = 'Rover'
    d.owner = barry
    d.person = gary
    d.previous_owner = jonno
    d.save!
    d
  end


  describe ".linked_from" do

    context "class name is specified" do
      it "creates a getter which returns the resources" do
        barry.owns_dogs.to_a == [rover, spot]
      end
    end

    context "class name is not specified" do
      it "creates a getter which returns the resources of the right class, based on the link name" do
        gary.dogs.to_a.should == [rover]
      end
    end

  end

  describe ".linked_to" do

    it "creates a getter for the field, with a default name, which returns the uri" do
      rover.owner_uri.should == barry.uri
    end

    it "creates a setter for the link" do
      rover.owner = gary
      rover.owner_uri.should == gary.uri
    end

    context 'the class name is specified' do
      it "creates a getter for the link, which returns a resource of the right type" do
        rover.owner.class.should == Person
        rover.owner.should == barry
      end
    end

    context 'the class name is not specified' do
      it "creates a getter for the link, which automatically returns a resource of the right type (from link name)" do
        rover.person.class.should == Person
        rover.person.should == gary
      end
    end

    context 'when the field name is set to an alternative field name' do
      it "uses that for the field name" do
        rover.prev_owner_uri.should == jonno.uri
      end
    end

    context 'its a multivalued field' do
      it "creates a getter and setter for multiple values, instantiating the right types of resource" do
        rover.friends = [fido, spot]

        rover.friends.each do |f|
          f.class.should == Dog
        end

        rover.friends.length.should == 2

        rover.friends.to_a.first.uri.should == fido.uri
        rover.friends.to_a.last.uri.should == spot.uri
      end

      it "creates field getters and setters with the _uris suffix" do
        rover.friends_uris = [fido.uri, spot.uri]
        rover.friends_uris.should == [fido.uri, spot.uri]
      end

    end

    context "when the value is not set for a link" do
      context "single valued" do
        it "should be nil" do
          rover.arch_enemy.should be_nil
        end
      end

      context "multivalued" do
        it "should be nil" do
          rover.enemies.should be_nil
        end
      end
    end
  end
end