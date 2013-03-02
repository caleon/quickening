# encoding: utf-8

require 'active_support/concern'

module CloneWars
  # == CloneWars::Model
  #
  # Module to include within your ActiveRecord::Base class definitions, either
  # manually or via the +clone_wars+ class method.
  module Model
    extend ActiveSupport::Concern

    included do
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
      scope :duplicate, ->(opts = {}) {
        select("`#{table_name}`.*").uniq.from("`#{table_name}` a2").
        joins("INNER JOIN `#{table_name}` USING (#{duplicate_matchers * ','})").
        where("`#{table_name}`.`id` != `a2`.`id`").
        order("`#{table_name}`.`id`").
        limit(opts[:force] ? nil : 0)
      } do

        ##
        #   User.duplicate.originals
        #   # => [#<User id: 1 name: 'Bruce Wayne', code: nil ..>,
        #         #<User id: 3 name: 'Syrio Forel', code: 50 died_on: "2013-03-01" ..>]
        def originals
          except(:limit).group(duplicate_matchers).having("`#{table_name}`.`id` = MIN(`#{table_name}`.`id`)")
        end

        ##
        #   User.duplicate.copies
        #   # => [#<User id: 2 name: 'Bruce Wayne', code: nil ..>,
        #         #<User id: 4 name: 'syrio forel', code: 50 died_on: nil ..>]
        def copies
          except(:limit).where("`a2`.`id` < `#{table_name}`.`id`")
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
    #     clone_wars :last_name, :ssn # via engines
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
    #     clone_wars [..]
    #
    #     # Custom overrides:
    #     module MyCloneWars
    #       def _duplicate_conditions
    #         @temporary_conditions || super
    #       end
    #     end
    #     include MyCloneWars
    #     ..
    #   end
    def _duplicate_conditions
      Hash[duplicate_matchers.map { |col| [col, send(col)] }]
    end
  end
end
