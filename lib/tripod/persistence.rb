# encoding: utf-8

# This module defines behaviour for persisting to the database.
module Tripod::Persistence
  extend ActiveSupport::Concern

  class Tripod::Persistence::Transaction

    def initialize
      self.transaction_id = Guid.new.to_s
    end

    attr_accessor :transaction_id
    attr_accessor :query

    def commit
      Tripod::SparqlClient::Update::update(self.query)
      clear_transaction
    end

    def abort
      clear_transaction
    end

    def clear_transaction
      self.transaction_id = nil
      self.query = ""
      Tripod::Persistence.transactions.delete(self.transaction_id)
    end

    def self.valid_transaction(transaction)
      transaction && transaction.class == Tripod::Persistence::Transaction
    end

    def self.get_transcation(trans)
      transaction = nil

      if Tripod::Persistence::Transaction.valid_transaction(trans)

        transaction_id = trans.transaction_id

        Tripod::Persistence.transactions ||= {}

        if Tripod::Persistence.transactions[transaction_id]
          # existing transaction
          transaction = Tripod::Persistence.transactions[transaction_id]
        else
          # new transaction
          transaction = Tripod::Persistence.transactions[transaction_id] = trans
        end
      end

      transaction
    end

  end

  # hash of transactions against their ids.
  mattr_accessor :transactions

  # Save the resource.
  # Note: regardless of whether it's a new_record or not, we always make the
  # db match the contents of this resource's statements.
  #
  # @example Save the resource.
  #   resource.save
  #
  # @return [ true, false ] True is success, false if not.
  def save(opts={})

    transaction = Tripod::Persistence::Transaction.get_transcation(opts[:transaction])

    if self.valid?

      query = "
        DELETE {GRAPH ?g {<#{@uri.to_s}> ?p ?o}} WHERE {GRAPH ?g {<#{@uri.to_s}> ?p ?o}};
        INSERT DATA {
          GRAPH <#{@graph_uri}> {
            #{ @repository.dump(:ntriples) }
          }
        };
      "

      if transaction
        transaction.query ||= ""
        transaction.query += query
      else
        Tripod::SparqlClient::Update::update(query)
      end

      @new_record = false # if running in a trans, just assume it worked. If the query is dodgy, it will throw an exception later.
      true
    else
      false
    end
  end

  # Save the resource, and raise an exception if it fails.
  # Note: As with save(), regardless of whether it's a new_record or not, we always make the
  # db match the contents of this resource's statements.
  #
  # @example Save the resource.
  #   resource.save
  #
  # @raise [Tripod::Errors::Validations] if invalid
  #
  # @return [ true ] True is success.
  def save!(opts={})
    # try to save
    unless self.save(opts)

      # if we get in here, save failed.

      # abort the transaction
      transaction = Tripod::Persistence::Transaction.get_transcation(opts[:transaction])
      transaction.abort() if transaction

      self.class.fail_validate!(self) # throw an exception

      # TODO: similar stuff for callbacks?
    end
    return true
  end

  def destroy(opts={})

    transaction = Tripod::Persistence::Transaction.get_transcation(opts[:transaction])

    query = "
      # delete from default graph:
      DELETE {<#{@uri.to_s}> ?p ?o} WHERE {<#{@uri.to_s}> ?p ?o};
      # delete from named graphs:
      DELETE {GRAPH ?g {<#{@uri.to_s}> ?p ?o}} WHERE {GRAPH ?g {<#{@uri.to_s}> ?p ?o}};
    "

    if transaction
      transaction.query ||= ""
      transaction.query += query
    else
      Tripod::SparqlClient::Update::update(query)
    end

    @destroyed = true
    true
  end

  module ClassMethods #:nodoc:

    # Raise an error if validation failed.
    #
    # @example Raise the validation error.
    #   Person.fail_validate!(person)
    #
    # @param [ Resource ] resource The resource to fail.
    def fail_validate!(resource)
      raise Tripod::Errors::Validations.new(resource)
    end

  end

end