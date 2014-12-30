require "spec_helper"

describe Tripod::Validations::IsUrlValidator do
  let(:person) { Person.new('http://example.com/barry') }

  it 'should be valid given a valid URL' do
    person.father = 'http://example.com/bob'
    person.should be_valid
  end

  it 'should be valid given a valid mailto URL' do
    person.father = 'mailto:hello@swirrl.com'
    person.should be_valid
  end

  it 'should invalidate given a non-http(s) URL' do
    person.father = 'ftp://example.com/bob.nt'
    person.should_not be_valid
  end

  it 'should invalidate given something unlike a URL' do
    person.father = 'http:Bob'
    person.should_not be_valid
  end

  it 'should invalidate given a domain without a TLD' do
    person.father = 'http://bob'
    person.should_not be_valid
  end
  
  it "should be valid with a port in the host" do
    person.father = 'http://localhost:3000/bob'
    person.should be_valid
  end
end