# encoding: utf-8

require 'active_support/concern'

module Quickening
  # == Quickening::Model
  #
  # Module to include within your ActiveRecord::Base class definitions, either
  # manually or via the +quickening+ class method.
  module Model
    extend ActiveSupport::Concern

    included do
      # The <tt>limit(0)</tt> default exists now to prevent any inadvertent calls
      # to what would amount to a very taxing call, for those on an app hooked
      # to a large database. Besides, there is more utility to be had when
      # following the scope call with one of the extensions.
      #
      #--
      # I have avoided the practice of using a join table to create a self-
      # referential association. Barring significant reasons to do so, a simple
      # alias to itself appears to hold more promise of an elegant solution.
      # Obviously there is a limit to how far SQL alone can go in terms of
      # providing us an efficient way to query these things, and those options
      # will be explored over time.
      #
      # In v0.0.1 the ARel methods and objects were directly utilized to avoid
      # needing to hardcode table alias names. But even if that worked
      # swimmingly as far as ARel was concerned, the interplay between it and
      # ActiveRecord rendered these methods ineffective or even broken. Ended
      # up interpolating code directly into strings, for a later time when a
      # better solution is pursued.
      #
      # Also it's worth considering making +duplicate_matchers+ unwritable even
      # at the class level once it's been set via +quickening+. The fact that it
      # would be inserted as a raw string in the midst of a query is undesirable
      # from a security standpoint.
      #++
      #
      # Note the scope name is not pluralized ("duplicate", not "duplicates"),
      # and a good way to think of this is to think of the word as an adjective
      # to deocorate either of the follow-up methods.
      #
      # There is a degree of caution required when depending on these scopes and
      # methods. Note that the <tt>#originals</tt> method performs a grouping
      # query, and depending on your usage, it may interject its own overriding
      # SELECT statements or table/column aliases.
      #
      # === Examples
      #
      #   User.duplicate # => []
      #
      #   User.duplicate(force: true)
      #   => [#<User id: 1 name: 'Bruce Wayne', code: nil ..>,
      #       #<User id: 2 name: 'Bruce Wayne', code: nil ..>,
      #       #<User id: 3 name: 'Syrio Forel', code: 50 died_on: "2013-03-01" ..>,
      #       #<User id: 4 name: 'syrio forel', code: 50 died_on: nil ..>,
      #       #<User id: 5 name: 'Marla Singer', code: 32 ..>,
      #       #<User id: 7 name: 'tylerdurden', code: 1 ..>,
      #       #<User id: 8 name: 'tyler durden', code: 1 ..>]
      # scope :duplicate, ->(opts = {}) {
      #   select("`#{table_name}`.*").uniq.from("`#{table_name}` a2").
      #   joins("INNER JOIN `#{table_name}` USING (#{duplicate_matchers * ', '})").
      #   where("`#{table_name}`.`id` != `a2`.`id`").
      #   order("`#{table_name}`.`id`").
      #   limit(opts[:force] ? nil : 0)
      # } do

      scope :duplicate, ->(opts = {}) {
        select("`#{table_name}`.*").
        uniq.
        joins("INNER JOIN `#{table_name}` a2 USING (#{duplicate_matchers * ', '})").
        where("`#{table_name}`.`id` != `a2`.`id`").
        order("`#{table_name}`.`id`").
        limit(opts[:force] ? nil : 0)
      } do


        ##
        # Returns a collection of all originals within each respective set of
        # duplicates. Make sure that part was clear. A read of the RSpec tests
        # with the "documentation" formatter may be assistive in clarifying the
        # intend of these methods.
        #
        #   User.duplicate.originals
        #   # => [#<User id: 1 name: 'Bruce Wayne', code: nil ..>,
        #         #<User id: 3 name: 'Syrio Forel', code: 50 died_on: "2013-03-01" ..>]
        def originals
          except(:limit).group(duplicate_matchers).
            having("`#{table_name}`.`id` = MIN(`#{table_name}`.`id`)")
        end

        ##
        #   User.duplicate.copies
        #   # => [#<User id: 2 name: 'Bruce Wayne', code: nil ..>,
        #         #<User id: 4 name: 'syrio forel', code: 50 died_on: nil ..>]
        def copies
          # except(:limit).where("`a2`.`id` < `#{table_name}`.`id`")
          except(:limit).where("`#{table_name}`.`id` > `a2`.`id`")
        end
      end
    end

    module ClassMethods #:nodoc:
      # Looks for other records in the same table for items matching on all
      # pre-defined columns. This has little benefit of usage except to act as
      # a proxy for the instance-level methods, such as <tt>#duplicates</tt>.
      #
      #   User.find_duplicates_for(user)
      #   # => [#<User id: 2 ..>]
      def find_duplicates_for(item)
        where(item._duplicate_conditions).
        where("`#{table_name}`.`id` != ?", item.id)
      end
    end

    # Returns a collection of records belonging to the same class/table which
    # matches on the designated columns.
    #
    #   <%= render partial: 'user/duplicate', collection: @user.duplicates %>
    def duplicates
      self.class.find_duplicates_for(self)
    end

    # Returns a hash meant to be used as a parameter to the query method
    # <tt>where(..)</tt>. To clarify the return value, if your model was set up like
    # this:
    #
    #   class User < ActiveRecord::Base
    #     quickening :last_name, :ssn
    #     ..
    #   end
    #
    # Then when you call a method utilizing this helper, such as
    # <tt>User#duplicates</tt>:
    #
    #   @user.last_name   # => 'Wayne'
    #   @user.ssn         # => '987-65-321'
    #   @user.duplicates  # => []
    #
    # ...the <tt>where(..)</tt> condition will receive the output of this method
    # and end up with the following:
    #
    #   where({ last_name: 'Wayne', ssn: '987-65-321' })
    #
    # Since the return of this method is simply injected into the +where+ method,
    # you could override this method and, theoretically, do something as follows:
    #
    #   def _duplicate_conditions
    #     ["first_name = ?, middle_name = ?, last_name = ?", *full_name.split]
    #   end
    #
    # However, as this breaks the unified definition of which columns are
    # expected to match, be sure you won't be breaking other aspects of the
    # integration of this library.
    #
    # ==== Alternate override
    #
    # If you want to maintain the library's method behavior but extend it a bit,
    # you might just want to follow the module extension scheme instead:
    #
    #   class User < ActiveRecord::Base
    #     quickening [..]
    #
    #     # Custom overrides:
    #     module DuncanMacLeod
    #       def _duplicate_conditions
    #         @temporary_conditions || super
    #       end
    #     end
    #     include DuncanMacLeod
    #     ..
    #   end
    def _duplicate_conditions
      Hash[duplicate_matchers.map { |col| [col, send(col)] }]
    end
  end
end
