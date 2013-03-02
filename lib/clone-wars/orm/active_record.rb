# encoding: utf-8

module CloneWars::ORM # :nodoc:

  module ActiveRecord # :nodoc:
    # In your model file, call +clone_wars+ method at the class-level, providing
    # it the columns you want the library to use as the basis for determining
    # whether or not records are "duplicates."
    #
    # In its present form, this comparison/matching is handled in a decidedly
    # black-and-white manner (although it's likely that many MySQL setups will
    # forgive case-insentivity).
    #
    #   class User < ActiveRecord::Base
    #     clone_wars %w(first_name last_name birthdate).map(&:to_sym)
    #     ..
    #   end
    #
    # ==== Parameters
    # * +attr_list+ - a list of symbolized attributes referencing column names
    #
    # It is only expecting a list, not an Array which could get flattened. For
    # now please remember this.
    def clone_wars(*attr_list)
      include CloneWars::Model
      class_attribute :duplicate_matchers, instance_writer: false
      self.duplicate_matchers = attr_list.map(&:to_sym) # Replace me in your models.
    end
  end

  # :singleton-method: duplicate_matchers
  # :singleton-method: duplicate_matchers=
  # :method: duplicate_matchers
end

ActiveRecord::Base.extend CloneWars::ORM::ActiveRecord
