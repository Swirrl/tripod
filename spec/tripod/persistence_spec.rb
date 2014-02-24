require "spec_helper"

describe Tripod::Persistence do

  let(:unsaved_person) do
    @unsaved_uri = @uri = 'http://example.com/uri'
    @graph1 = RDF::Graph.new
    stmt = RDF::Statement.new
    stmt.subject = RDF::URI.new(@uri)
    stmt.predicate = RDF::URI.new('http://example.com/pred')
    stmt.object = RDF::URI.new('http://example.com/obj')
    @graph1 << stmt
    p = Person.new(@uri, 'http://example.com/graph')
    p.hydrate!(:graph => @graph1)
    p
  end

  let(:saved_person) do
    @saved_uri = @uri2 = 'http://example.com/uri2'
    @graph2 = RDF::Graph.new
    stmt = RDF::Statement.new
    stmt.subject = RDF::URI.new(@uri2)
    stmt.predicate = RDF::URI.new('http://example.com/pred2')
    stmt.object = RDF::URI.new('http://example.com/obj2')
    @graph2 << stmt
    p = Person.new(@uri2, 'http://example.com/graph')
    p.hydrate!(:graph => @graph2)
    p.save
    p
  end


  describe ".save" do

    context "with no graph_uri set" do
      it 'should raise a GraphUriNotSet error' do
        p = Resource.new('http://example.com/arbitrary/resource')
        lambda { p.save }.should raise_error(Tripod::Errors::GraphUriNotSet)
      end
    end

    it 'saves the contents to the db' do
      unsaved_person.save.should be_true

      # try reading the data back out.
      p2 = Person.new(@uri)
      p2.hydrate!
      repo_statements = p2.repository.statements
      repo_statements.count.should == 1
      repo_statements.first.subject.should == RDF::URI.new(@uri)
      repo_statements.first.predicate.should == RDF::URI.new('http://example.com/pred')
      repo_statements.first.object.should == RDF::URI.new('http://example.com/obj')
    end


    it 'should leave other people untouched' do
      # save the unsaved person
      unsaved_person.save.should be_true

      # read the saved person back out the db, and check he's untouched.
      p2 = Person.new(saved_person.uri)
      p2.hydrate!
      p2.repository.dump(:ntriples).should == saved_person.repository.dump(:ntriples)
    end

    it 'runs the callbacks' do
      unsaved_person.should_receive(:pre_save)
      unsaved_person.save
    end
  end

  describe ".destroy" do

    it 'removes all triples from the db' do
      saved_person.destroy.should be_true

      # re-load it back into memory
      p2 = Person.new(@saved_uri)
      p2.hydrate!
      p2.repository.should be_empty # nothing there any more!
    end

    it 'should run the callbacks' do
      saved_person.should_receive(:pre_destroy)
      saved_person.destroy
    end
  end

  describe ".save!" do
    it 'throws an exception if save fails' do
      unsaved_person.stub(:graph_uri).and_return(nil) # force a failure
      lambda {unsaved_person.save!}.should raise_error(Tripod::Errors::Validations)
    end
  end

  describe '.update_attribute' do
    let (:person) { Person.new('http://example.com/newperson') }
    
    context 'without transactions' do
      before { person.stub(:save) }

      it 'should write the attribute' do
        person.update_attribute(:name, 'Bob')
        person.name.should == 'Bob'
      end

      it 'should save the record' do
        person.should_receive(:save)
        person.update_attribute(:name, 'Bob')
      end
    end

    context 'with transactions' do
      it 'should create a new resource' do
        transaction = Tripod::Persistence::Transaction.new

        person.update_attribute(:name, 'George', transaction: transaction)

        lambda { Person.find(person.uri) }.should raise_error(Tripod::Errors::ResourceNotFound)
        transaction.commit
        lambda { Person.find(person.uri) }.should_not raise_error()
      end

      it 'should assign the attributes of an existing' do
        transaction = Tripod::Persistence::Transaction.new
        person.save

        person.update_attribute(:name, 'George', transaction: transaction)

        Person.find(person.uri).name.should_not == 'George'
        transaction.commit
        Person.find(person.uri).name.should == 'George'
      end
    end
  end

  describe '.update_attributes' do
    let (:person) { Person.new('http://example.com/newperson') }
    
    context "without transactions" do
      before { person.stub(:save) }

      it 'should assign the attributes' do
        person.update_attributes(:name => 'Bob')
        person.name.should == 'Bob'
      end

      it 'should save the record' do
        person.should_receive(:save)
        person.update_attributes(:name => 'Bob')
      end
    end

    context 'with transactions' do

      it 'should create a new resource' do
        transaction = Tripod::Persistence::Transaction.new
        attributes = { name: 'Fred' }

        person.update_attributes(attributes, transaction: transaction)

        lambda { Person.find(person.uri) }.should raise_error(Tripod::Errors::ResourceNotFound)
        transaction.commit
        lambda { Person.find(person.uri) }.should_not raise_error()
      end

      it 'should assign the attributes of an existing' do
        transaction = Tripod::Persistence::Transaction.new
        attributes = { name: 'Fred' }
        person.save

        person.update_attributes(attributes, transaction: transaction)

        Person.find(person.uri).name.should_not == 'Fred'
        transaction.commit
        Person.find(person.uri).name.should == 'Fred'
      end
    end
  end

  describe "transactions" do

    it "only saves on commit" do

      transaction = Tripod::Persistence::Transaction.new

      unsaved_person.save(transaction: transaction)
      saved_person.write_predicate('http://example.com/pred2', 'blah')
      saved_person.save(transaction: transaction)

      # nothing should have changed yet.
      lambda {Person.find(unsaved_person.uri)}.should raise_error(Tripod::Errors::ResourceNotFound)
      Person.find(saved_person.uri).read_predicate('http://example.com/pred2').first.to_s.should == RDF::URI.new('http://example.com/obj2').to_s

      transaction.commit

      # things should have changed now.
      lambda {Person.find(unsaved_person.uri)}.should_not raise_error()
      Person.find(saved_person.uri).read_predicate('http://example.com/pred2').first.should == 'blah'

    end

    it "silently ignore invalid saves" do
      transaction = Tripod::Persistence::Transaction.new

      unsaved_person.stub(:graph_uri).and_return(nil) # force a failure
      unsaved_person.save(transaction: transaction).should be_false

      saved_person.write_predicate('http://example.com/pred2', 'blah')
      saved_person.save(transaction: transaction).should be_true

      transaction.commit

      # transaction should be gone
      Tripod::Persistence.transactions[transaction.transaction_id].should be_nil

      # unsaved person still not there
      lambda {Person.find(unsaved_person.uri)}.should raise_error(Tripod::Errors::ResourceNotFound)

      # saved person SHOULD be updated
      Person.find(saved_person.uri).read_predicate('http://example.com/pred2').first.should == 'blah'
    end

    it "can be aborted" do
      transaction = Tripod::Persistence::Transaction.new
      unsaved_person.save(transaction: transaction)
      transaction.abort()

      # unsaved person still not there
      lambda {Person.find(unsaved_person.uri)}.should raise_error(Tripod::Errors::ResourceNotFound)

      #transaction gone.
      transaction.query.should be_blank
      Tripod::Persistence.transactions[transaction.transaction_id].should be_nil
    end

    it "should be removed once committed" do
      transaction = Tripod::Persistence::Transaction.new
      unsaved_person.save(transaction: transaction)
      transaction.commit()

      #transaction gone.
      transaction.query.should be_blank
      Tripod::Persistence.transactions[transaction.transaction_id].should be_nil
    end

  end

end