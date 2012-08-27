# encoding: utf-8

# This module contains the behaviour for getting the various states through which a
# resource can transition.
module Tripod::State

  extend ActiveSupport::Concern

  attr_writer :destroyed, :new_record

  # Returns true if the +Resource+ has not been persisted to the database,
  # false if it has. This is determined by the variable @new_record
  # and NOT if the object has an id.
  #
  # @example Is the resource new?
  #   person.new_record?
  #
  # @return [ true, false ] True if new, false if not.
  def new_record?
    @new_record ||= false
  end

  # Checks if the resource has been saved to the database. Returns false
  # if the resource has been destroyed.
  #
  # @example Is the resource persisted?
  #   person.persisted?
  #
  # @return [ true, false ] True if persisted, false if not.
  def persisted?
    !new_record? && !destroyed?
  end

  # Returns true if the +Resource+ has been succesfully destroyed, and false
  # if it hasn't. This is determined by the variable @destroyed and NOT
  # by checking the database.
  #
  # @example Is the resource destroyed?
  #   person.destroyed?
  #
  # @return [ true, false ] True if destroyed, false if not.
  def destroyed?
    @destroyed ||= false
  end
  alias :deleted? :destroyed?

end