require 'spec_helper'

describe Tripod::Embeds do
  let(:dog) {
    d = Dog.new('http://example.com/id/spot')
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
