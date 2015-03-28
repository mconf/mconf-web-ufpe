# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

FactoryGirl.define do
  factory :ldap_token do
    association :user, factory: :user
    data "MyText"
    after(:build) do |obj|
      obj.identifier = obj.user.email
    end
  end
end
