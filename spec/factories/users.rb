FactoryBot.define do
  factory :user do
    cognito_sub { "MyString" }
    email { "MyString" }
    nickname { "MyString" }
  end
end
