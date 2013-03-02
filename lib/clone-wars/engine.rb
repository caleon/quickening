# encoding: utf-8

module CloneWars # :nodoc:

  class Engine < ::Rails::Engine # :nodoc:
    isolate_namespace CloneWars

    config.clone_wars = CloneWars

    initializer 'clone_wars.active_record' do
      ActiveSupport.on_load :active_record do
        require 'clone-wars/orm/active_record'
      end
    end

  end
end
