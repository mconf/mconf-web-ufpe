require 'net/ldap'
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class LdapAuthenticatable < Authenticatable

      def authenticate!
        if params[:user] and params[:ldap_auth] and ldap_enabled?
          Rails.logger.info "LDAP: authenticating a user"

          ldap_server = ldap_from_site
          ldap = ldap_connection(ldap_server)
          ldap.auth ldap_server.ldap_user, ldap_server.ldap_user_password

          # Tries to bind to the ldap server
          if ldap.bind
            Rails.logger.info "LDAP: bind of the configured user was successful"
            Rails.logger.info "LDAP: trying to bind the target user: #{params[:user][:login]}"

            # Tries to authenticate the user to the ldap server
            ldap_user = ldap.bind_as(:base => ldap_server.ldap_user_treebase, :filter => ldap_filter(ldap_server), :password => password)
            if ldap_user
              Rails.logger.info "LDAP: user successfully authenticated: #{ldap_user}"

              # login or create the account
              # TODO: verify if the ldap_user has the attributes we need, otherwise return an error
              user = find_or_create_user(ldap_user.first, ldap_server)
              success!(user, I18n.t('devise.strategies.ldap_authenticatable.login_successful', :username => params[:user][:login]))
            else
              Rails.logger.error "LDAP: authentication failed, response: #{ldap_user}"
              fail!(:invalid)
            end
          else
            Rails.logger.error "LDAP: could not bind the configured user, check your configurations"
            fail!(I18n.t('devise.strategies.ldap_authenticatable.invalid_bind'))
          end

        # user did not select to authenticate via ldap
        elsif not params[:ldap_auth]
          fail(:invalid)

        # ldap is not enable in the site
        elsif not ldap_enabled?
          fail!(I18n.t('devise.strategies.ldap_authenticatable.ldap_not_enabled'))

        else
          fail!(:invalid)
        end
      end

       # Returns the login provided by user
      def login
        params[:user][:login]
      end

      # Returns the password provided by user
      def password
        params[:user][:password]
      end

      # Returns the current Site so we can get the ldap variables
      def ldap_from_site
        Site.current
      end

      # Returns the filter to bind the user
      def ldap_filter(ldap)
        Net::LDAP::Filter.eq(ldap.ldap_username_field, login)
      end

     # Returns true if the ldap is enabled in Mconf Portal
      def ldap_enabled?
        ldap_from_site.ldap_enabled?
      end

      # Creates the ldap variable to connect to ldap server
      # port 636 means LDAPS, so whe use encryption (simple_tls)
      # else there is no security (usually port 389)
      def ldap_connection(ldap)
        if ldap.ldap_port == 636
          Net::LDAP.new(:host => ldap.ldap_host, :port => ldap.ldap_port, :encryption => :simple_tls)
        else
          Net::LDAP.new(:host => ldap.ldap_host, :port => ldap.ldap_port)
        end
      end

      # Creates the internal structures for the `ldap_user` using the ldap information
      # as configured in `ldap_configs`.
      def find_or_create_user(ldap_user, ldap_configs)
        Rails.logger.info "LDAP: logging a user in"

        # get the username, full name and email from the data returned by the server
        if ldap_user[ldap_configs.ldap_username_field]
          ldap_username = ldap_user[ldap_configs.ldap_username_field].first
        else
          ldap_username = ldap_user.uid
        end
        if ldap_user[ldap_configs.ldap_name_field]
          ldap_name = ldap_user[ldap_configs.ldap_name_field].first
        else
          ldap_name = ldap_user.cn
        end
        if ldap_user[ldap_configs.ldap_email_field]
          ldap_email = ldap_user[ldap_configs.ldap_email_field].first
        else
          ldap_email = ldap_user.mail
        end

        # creates the token and the internal account, if needed
        token = find_or_create_token(ldap_email)
        token.user = create_account(ldap_email, ldap_username, ldap_name)
        token.save!
        token.user
      end

      # Searches for a LdapToken using the user email as identifier
      # Creates one token if none is found
      def find_or_create_token(id)
        token = LdapToken.find_by_identifier(id)
        token = LdapToken.create!(:identifier => id) if token.nil?
        token
      end

      # Create the user account if there is no user with the email provided by ldap
      # Or returns the existing account with the email
      def create_account(id, username, full_name)
        unless User.find_by_email(id)
          Rails.logger.info "LDAP: creating a new account for email '#{id}', username '#{username}', full name: #{full_name}"
          password = SecureRandom.hex(16)
          params = {
            :username => username,
            :email => id,
            :password => password,
            :password_confirmation => password,
            :_full_name => full_name
          }
          user = User.new(params)
          user.skip_confirmation!
          user
        else
          User.find_by_email(id)
        end
      end

    end
  end
end

Warden::Strategies.add(:ldap_authenticatable, Devise::Strategies::LdapAuthenticatable)