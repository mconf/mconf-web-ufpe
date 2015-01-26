# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

class SessionLocalesController < ActionController::Base

  def create
    new_locale = params[:l]

    if I18n.locale_available?(new_locale)
      locale_name = t("locales.#{new_locale}")

      # add locale to the session
      session[:locale] = new_locale

      # set the locale as the default for this user
      current_user.update_attribute(:locale, new_locale) if user_signed_in?

      flash[:success] = t('session_locales.create.success', :value => locale_name, :locale => new_locale)
    else
      flash[:error] = t('locales.error', :value => locale_name)
    end

    redirect_to after_create_path
  end

  private

  # Returns the URL to which we should redirect after changing the language.
  def after_create_path
    ref = URI(request.referer).path

    # Some paths we don't want to redirect back to (usually routes that won't respond to
    # a GET request).
    if [user_registration_path].include?(ref)
      register_path
    elsif [new_user_session_path].include?(ref)
      login_path
    else
      ref
    end
  end

end
