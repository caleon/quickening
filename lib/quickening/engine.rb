# encoding: utf-8

module Quickening # :nodoc:

  class Engine < ::Rails::Engine # :nodoc:
    isolate_namespace Quickening

    config.quickening = Quickening

    initializer 'quickening.active_record' do
      ActiveSupport.on_load :active_record do
        require 'quickening/orm/active_record'
      end
    end
  end
end
