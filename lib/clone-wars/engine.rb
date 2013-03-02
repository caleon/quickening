module CloneWars
  class Engine < ::Rails::Engine
    isolate_namespace CloneWars

    config.clone_wars = CloneWars

    initializer "clone_wars.active_record" do
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.extend CloneWars::ModelBase
      end
    end

  end
end
