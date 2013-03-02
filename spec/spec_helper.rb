require 'rubygems'

def setup_environment
  ENV["RAILS_ENV"] ||= 'test'

  require File.expand_path("../dummy/config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'
  require 'faker'
  require 'factory_girl_rails'

  # Rails.backtrace_cleaner.remove_silencers!

  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.run_all_when_everything_filtered = true
    config.filter_run :focus
    config.mock_with :rspec
    config.use_transactional_fixtures = true
    config.infer_base_class_for_anonymous_controllers = true
    config.order = "random"

    # config.fixture_path = "#{::Rails.root}/spec/fixtures"
    config.include FactoryGirl::Syntax::Methods
  end
end

def each_run

end

if(begin; require 'spork'; rescue LoadError; nil end).nil? || !Spork.using_spork?
  # require 'simplecov'
  setup_environment
  each_run
else
  # require 'spork/ext/ruby-debug'
  Spork.prefork do
    ENV['DRB'] = 'true'
    # Spork.trap_method(Rails::Application::RoutesReloader, :reload!)
    setup_environment
    # ActiveSupport::Dependencies.clear
  end

  Spork.each_run do
    # require 'simplecov'
    each_run
  end
end
