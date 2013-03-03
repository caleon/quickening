# CloneWars

CloneWars is a Rails gem for adding to your model a facility to query and manage duplicate records. It's been written to remain relatively abstract and adaptable to various models, and so the library should be an easy plugin for models you may have set up already (barring name clashes).

Beyond the abstracted query methods for searching efficiently throughout the table (but only tested against MySQL 5.5, sorry), your models gain access to methods for dispending with duplicates, chores varying in complexity ranging from the trivial deletes to customizable merges (future feature).

This gem was built against Rails 3.2.12 on Ruby 2.0.0-p0 (although only using things available as of 1.9.3). Rails 3.1 doesn't handle the `uniq` relational
query method, but that should not matter. I don't believe `from` is handled in either 3.0 or 3.1, so that might be a showstopper with pre-3.2 Rails setups. Ruby 1.9 syntaxes are prevalent, so this will not be compatible with Ruby 1.8, either.

But if you see the utility of this sort of gem, please feel free to contribute and help out.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'clone-wars', github: 'caleon/clone-wars'
```

And then execute:

```bash
$ bundle
```

Setup your model one way (the old way):

```ruby
require 'clone-wars'

class User < ActiveRecord::Base
  include CloneWars::Model
  self.duplicate_matchers = %w(name code).map(&:to_sym)
  ..
end
```

...or the other way (new way, using Rails Engines):

```ruby
class User < ActiveRecord::Base
  clone_wars :name, :code
  ..
end
```

And in your migration:

```ruby
add_index :users, [:name, :code]
```

The order by which your composite index is defined should match that of your class attribute value.

## Usage

### Retrieve all non-unique records

```ruby
> User.duplicate
# => []

> User.duplicate(force: true)
# => [#<User id: 1 name: 'Bruce Wayne', code: nil ..>,
      #<User id: 2 name: 'Bruce Wayne', code: nil ..>,
      #<User id: 3 name: 'Syrio Forel', code: 50, died_on: "2013-03-01" ..>,
      #<User id: 4 name: 'syrio forel', code: 50, died_on: nil ..>,
      #<User id: 5 name: 'Marla Singer', code: 32 ..>,
      #<User id: 7 name: 'tylerdurden', code: 1 ..>,
      #<User id: 8 name: 'tyler durden', code: 1 ..>]
```

The conditions of their non-uniqueness is determined by checking the rest of the table using the `User.duplicate_matches` setting (which works with an Array only, with no special provisions yet for Procs or anything). If a record exists which is identical on all those fields, it is a part of the returned value. This means that both the "original" record as well as its (potentially multiple) copies will be included.

#### Force: true

Note that because tables requiring these operations could get potentially large, and because this library does not assume that you have properly applied indexes to the columns used for operational queries, the computation of this finder may be too strenuous. To prevent accidental triggers of this method which, on its own, provides less utility than the chained methods described below, it is initially restricted with `limit(0)` which will then be unrestricted when the follow-up methods are called.

Obviously you can override this yourself with something like `except(:limit)` or by calling another limit. Alternatively, you can pass the option for `force: true` to the method.


### Retrieve just the originals

```ruby
> User.duplicate.originals
# => [#<User id: 1 name: 'Bruce Wayne', code: nil ..>,
      #<User id: 3 name: 'Syrio Forel', code: 50, died_on: "2013-03-01" ..>]
```

So far as this initial version is concerned, the "originality" is determined by returning the record with the lowest ID among the matches. Also, it is not concerned a duplicate-original if it is a unique record to begin with.

Note that this does not return *the* original, since among many sets of matches, there is no single "original". Thus, to act on one original record out of a particular set of duplicates, you would need to scope down the returned set as follows:

```ruby
> User.duplicate.originals.where(name: 'Bruce Wayne').first
# => [#<User id: 1 name: 'Bruce Wayne', code: nil ..>]
```

For the sake of clarity, there should later be an aptly-named method for such individual cases.


### Retrieve just the copies

```ruby
> User.duplicate.copies
# => [#<User id: 2 name: 'Bruce Wayne', code: nil ..>,
      #<User id: 4 name: 'syrio forel', code: 50, died_on: nil ..>]
```

This can otherwise be described as the set of all duplicated records without the original records:

```ruby
> User.duplicate.copies == User.duplicate(force: true) - User.duplicate.originals
# => true
```

## Future

1. ~~Consider a class method as an alternative to requiring-including-setting.~~
2. Lower the version dependency for Rails (indirectly via ActiveRecord/ActiveSupport)
3. *Perhaps* rewrite hash syntaxes to allow Ruby 1.8 compatibility...
4. Write more utility functions for dealing with duplicates.
5. Allow customization of how to determine a record's "originality".
6. Create generators for automatically inputting the required lines into a model file as well as a new migration for adding indices to the appropriate columns.
7. Setup faux model classes to allow an instance of a returned set to behave in a special way, distinguishing it from normal records.
8. Further avoid MySQL-specific code and test against Postgres, SQLite, etc.
9. Controller at the engine- or Rack- level for pre-made administrative interface for managing and reporting duplicates.
10. Ability to turn on caching of duplicates per model instance.

## Contributing to clone-wars

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2013 caleon. See MIT-LICENSE for further details.
