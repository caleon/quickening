# encoding: utf-8

$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "quickening/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'quickening'
  s.version     = Quickening::VERSION
  s.authors     = ['caleon']
  s.email       = ['caleon@gmail.com']
  s.homepage    = 'https://github.com/caleon/quickening'
  s.summary     = %Q{Quickening is a Rails gem for adding to your model a facility to query and manage duplicate records.}
  s.description = <<-EOD
    Quickening is a Rails gem for adding to your model a facility to query and manage duplicate records. It's been written to remain relatively abstract and adaptable to various models, and so the library should be an easy plugin for models you may have set up already (barring name clashes).

    Beyond the abstracted query methods for searching efficiently throughout the table (but only tested against MySQL 5.5, sorry), your models gain access to methods for dispending with duplicates, chores varying in complexity ranging from the trivial deletes to customizable merges (future feature).
  EOD

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md", "CHANGELOG.rdoc"]

  s.required_ruby_version = '>= 1.9.2'

  s.add_dependency 'rails', '~> 3.2.12'
  s.add_dependency 'activerecord', '~> 3.2.12'
  # s.add_dependency "jquery-rails"

  s.add_development_dependency "sqlite3"

  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rspec-rails', '>= 2.12'
  s.add_development_dependency 'turnip'
  # s.add_development_dependency 'capybara'
  # s.add_development_dependency 'poltergeist'
  s.add_development_dependency 'faker'
  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'guard-spork'
  s.add_development_dependency 'ruby-prof'

  s.test_files = Dir['spec/**/*']
end
