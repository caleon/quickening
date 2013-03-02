$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "clone-wars/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'clone-wars'
  s.version     = CloneWars::VERSION
  s.authors     = ['caleon']
  s.email       = ['caleon@gmail.com']
  s.homepage    = 'https://github.com/caleon/clone-wars'
  s.summary     = %Q{CloneWars is a Rails gem for adding to your model a facility to query and manage duplicate records.}
  s.description = <<-EOD
    CloneWars is a Rails gem for adding to your model a facility to query and manage duplicate records. It's been written to remain relatively abstract and adaptable to various models, and so the library should be an easy plugin for models you may have set up already (barring name clashes).

    Beyond the abstracted query methods for searching efficiently throughout the table (but only tested against MySQL 5.5, sorry), your models gain access to methods for dispending with duplicates, chores varying in complexity ranging from the trivial deletes to customizable merges (future feature).
  EOD

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 3.2.12"
  # s.add_dependency "jquery-rails"

  s.add_development_dependency "sqlite3"

  s.add_development_dependency 'rspec-rails', '>= 2.12'
  # s.add_development_dependency 'capybara'
  # s.add_development_dependency 'poltergeist'
  s.add_development_dependency 'factory_girl_rails'
  # s.add_development_dependency "rcov", ">= 0"

  s.test_files = Dir['spec/**/*']
end