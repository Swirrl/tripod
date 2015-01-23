require 'spec_helper'

describe Tripod::Embeds do
  let(:uri) { 'http://example.com/id/spot' }
  let(:dog) {
    d = Dog.new(uri)
    d.name = "Spot"
    d
  }
  let(:flea) {
    f = Flea.new
    f.name = 'Starsky'
    f
  }

  it 'should set and get embedded resources through the proxy' do
    dog.fleas << flea
    expect(dog.fleas.include?(flea)).to eq(true)
  end

  it 'should validate embedded resources' do
    dog.fleas << Flea.new
    expect(dog.valid?).to eq(false)
  end

  context 'given a saved instance' do
    before do
      dog.fleas << flea
      dog.save
    end

    context 'retrieved by uri' do
      let(:dogg) { Dog.find(uri) }

      it 'should hydrate embedded resources from the triple store' do
        f = dogg.fleas.first
        expect(f.name).to eq(flea.name)
      end
    end

    context 'retrieved as part of a resource collection' do
      let(:dogg) { Dog.all.resources.first }

      it 'should hydrate embedded resources from the triple store' do
        f = dogg.fleas.first
        expect(f.name).to eq(flea.name)
      end
    end
  end


  describe 'delete' do
    before do
      dog.fleas << flea
    end

    it 'should remove all trace of the resource' do
      dog.fleas.delete(flea)
      expect(dog.fleas.include?(flea)).to eq(false)
    end
  end
end
