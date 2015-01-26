# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

FactoryGirl.define do
  factory :unconfirmed_user, class: User do
    username
    email
    sequence(:_full_name) { |n| Forgery::Name.unique_full_name(n) }
    association :bigbluebutton_room
    association :profile
    created_at { Time.now }
    updated_at { Time.now }
    disabled false
    approved true
    superuser false
    receive_digest { User::RECEIVE_DIGEST_NEVER }
    password { Forgery::Basic.password :at_least => 6, :at_most => 16 }
    password_confirmation { |user| user.password }
    needs_approval_notification_sent_at { Time.now }
    approved_notification_sent_at { Time.now }
    before(:create) { |user| user.skip_confirmation_notification! }
    after(:create) { |user|
      # for some reason the user ends up without a full name, only b/c he's unconfirmed
      user.profile.update_attribute(:full_name, user._full_name)
      user.reload
    }

    factory :user, parent: :unconfirmed_user do
      confirmed_at { Time.now }
      after(:create) { |user| user.confirm!; user.reload }

      factory :superuser, class: User, parent: :user do |u|
        u.superuser true
      end
    end
  end

end
