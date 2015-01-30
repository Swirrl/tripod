require 'spec_helper'

describe Tripod::Dirty do
  let(:dog) { Dog.new('http://example.com/dog/spot') }

  describe '#changes' do
    before do
      dog.name = 'Spot'
    end

    it 'should report the original and current values for a changed field' do
      expect(dog.changes[:name]).to eq([nil, 'Spot'])
    end

    context 'when the field is set more than once' do
      before do
        dog.name = 'Zit'
      end

      it 'should still report the original value correctly' do
        expect(dog.changes[:name]).to eq([nil, 'Zit'])
      end
    end

    context 'when the field is set back to its original value' do
      before do
        dog.name = nil
      end

      it 'should no longer report a change to the field' do
        expect(dog.changes.keys).to_not include(:name)
      end
    end

    context 'on save' do
      before { dog.save }

      it 'should reset changes' do
        expect(dog.changes).to be_empty
      end
    end
  end

  context 'field methods' do
    before { dog.name = 'Wrex' }

    it 'should create a <field>_change method' do
      expect(dog.name_change).to eq([nil, 'Wrex'])
    end

    it 'should create a <field>_changed? method' do
      expect(dog.name_changed?).to eq(true)
    end

    it 'should create a <field>_was method' do
      expect(dog.name_was).to eq(nil)
    end
  end
end
