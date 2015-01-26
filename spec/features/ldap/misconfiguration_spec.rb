require 'spec_helper'
require 'support/feature_helpers'

include ActionView::Helpers::SanitizeHelper

feature 'LDAP is misconfigured' do
  subject { page }
  before {
    Site.current.update_attributes ldap_enabled: true
  }

  scenario "doesn't break the local sign in" do
    Site.current.update_attributes ldap_host: "127.0.0.1"

    user = FactoryGirl.create(:user, :username => 'user', :password => 'password')
    sign_in_with user.email, user.password

    expect(page).to have_title(I18n.t('home.my'))
    expect(page).to have_content(I18n.t('home.my_spaces'))
    expect(current_path).to eq(my_home_path)
  end
end
