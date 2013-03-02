require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../dummy/config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'
  require 'factory_girl_rails'

  Rails.backtrace_cleaner.remove_silencers!

  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.run_all_when_everything_filtered = true
    config.filter_run :focus
    config.mock_with :rspec
    # config.fixture_path = "#{::Rails.root}/spec/fixtures"
    config.use_transactional_fixtures = true
    config.infer_base_class_for_anonymous_controllers = true
    config.order = "random"
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.
end
