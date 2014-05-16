# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :tweet do
    user "MyString"
    content "MyText"
    coordinates ""
  end
end
