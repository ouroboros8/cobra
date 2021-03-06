FactoryGirl.define do
  factory :player do
    name { Faker::Name.name }
    tournament { Tournament.first || create(:tournament) }
    active true
  end
end
