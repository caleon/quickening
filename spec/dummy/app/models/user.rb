class User < ActiveRecord::Base
  # include Juscribe::Personhood
  attr_accessible :first_name, :middle_name, :last_name

  quickening :first_name, :last_name
end
