# encoding: utf-8

FactoryGirl.define do

  factory :user do

    email { Faker::Internet.email }
    first_name { Faker::Name.first_name }
    middle_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    birthdate '1985-01-29'
  end
end
