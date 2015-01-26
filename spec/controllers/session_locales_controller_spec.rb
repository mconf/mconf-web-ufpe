# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require "spec_helper"

# for get_user_locale
include Mconf::LocaleControllerModule

describe SessionLocalesController do

  describe "#create" do

    let(:old_locale) { I18n.locale }
    let!(:locale) { 'pt-br' }
    let!(:locale_name) { I18n.t("locales.#{locale}") }
    let(:user) { FactoryGirl.create(:user) }
    let!(:url) { '/any' }

    before {
      request.env['HTTP_REFERER'] = url
      sign_in(user)
    }

    context 'on success' do
      before {
        post :create, :l => locale
        user.reload
      }
      it { should redirect_to url }
      it { should set_the_flash.to(I18n.t('session_locales.create.success', :value => locale_name, :locale => locale))}
      it { get_user_locale(user, false).should eq(locale.to_sym) }
      it { session[:locale].should eq(locale) }
      it { user.locale.should eq(locale) }
    end

    context "on inexistant locale" do
      let(:locale) { 'fr' }
      before {
        post :create, :l => locale
        user.reload
      }

      it { should redirect_to url }
      it { should set_the_flash.to(I18n.t('locales.error'))}
      it { get_user_locale(user, false).should_not eq(locale.to_sym) }
      it { session[:locale].should_not eq(locale) }
      it { user.locale.should_not eq(locale) }
    end

    context 'when the referer was' do
      context 'user_registration_path' do
        before {
          request.env['HTTP_REFERER'] = user_registration_path
          post :create, :l => locale
        }
        it { should redirect_to register_path }
      end

      context 'new_user_session_path' do
        before {
          request.env['HTTP_REFERER'] = new_user_session_path
          post :create, :l => locale
        }
        it { should redirect_to login_path }
      end
    end

  end

end
