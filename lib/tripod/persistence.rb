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
      Tripod::SparqlClient::Update.update(self.query)
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

    def self.get_transaction(trans)
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
    run_callbacks :save do
      raise Tripod::Errors::GraphUriNotSet.new() unless @graph_uri

      transaction = Tripod::Persistence::Transaction.get_transaction(opts[:transaction])

      if self.valid?
        graph_selector = self.graph_uri.present? ? "<#{graph_uri.to_s}>" : "?g"
        query = "
          DELETE {GRAPH #{graph_selector} {<#{@uri.to_s}> ?p ?o}} WHERE {GRAPH #{graph_selector} {<#{@uri.to_s}> ?p ?o}};
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
      transaction = Tripod::Persistence::Transaction.get_transaction(opts[:transaction])
      transaction.abort() if transaction

      self.class.fail_validate!(self) # throw an exception

      # TODO: similar stuff for callbacks?
    end
    return true
  end

  def destroy(opts={})
    run_callbacks :destroy do
      transaction = Tripod::Persistence::Transaction.get_transaction(opts[:transaction])

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
  end

  def update_attribute(name, value, opts={})
    write_attribute(name, value)
    save(opts)
  end

  def update_attributes(attributes, opts={})
    attributes.each_pair do |name, value|
      send "#{name}=", value
    end
    save(opts)
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
