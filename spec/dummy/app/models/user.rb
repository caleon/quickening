class User < ActiveRecord::Base
  # include Juscribe::Personhood
  attr_accessible :first_name, :middle_name, :last_name

  clone_wars :first_name, :last_name
end
