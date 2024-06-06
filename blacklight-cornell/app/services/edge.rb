require "cul/folio/edge/version"
require "rest-client"
require "json"

module CUL
  module FOLIO
    module Edge
      class Error < StandardError; end

      ##
      # Connects to an Okapi instance and uses the +/authn/login+ endpoint
      # to authenticate the user.
      #
      # Params:
      # +okapi+:: URL of an okapi instance (e.g., "https://folio-snapshot-okapi.dev.folio.org")
      # +tenant+:: FOLIO/OKAPI tenant ID
      # +username+:: Username
      # +password+:: Password
      #
      # Return:
      # A hash containing:
      # +:token+:: An Okapi X-Okapi-Token string, or nil
      # +:code+:: An HTTP response code
      # +:error+:: An error message, or nil
      ##
      def self.authenticate(okapi, tenant, username, password)
        url = "#{okapi}/authn/login"
        headers = {
          "X-Okapi-Tenant" => tenant,
          :accept => "application/json",
          "X-Forwarded-For" => "Stripes",
          :content_type => "application/json",
        }
        body = {
          "username" => username,
          "password" => password,
        }.to_json
        return_value = {
          :token => nil,
          :error => nil,
        }
        begin
          response = RestClient.post(url, body, headers)
          return_value[:token] = response.headers[:x_okapi_token]
          return_value[:code] = response.code
        rescue RestClient::ExceptionWithResponse => err
          return_value[:code] = err.response.code
          return_value[:error] = err.response.body
        end
        return return_value
      end
      ##
      # Connects to an Okapi instance and uses the +/users+ endpoint
      # to retrieve a user's FOLIO record.
      #
      # Params:
      # +okapi+:: URL of an okapi instance (e.g., "https://folio-snapshot-okapi.dev.folio.org")
      # +tenant+:: An Okapi tenant ID
      # +token+:: An Okapi token string from a previous authentication call
      # +username+:: The 'username' property of a user record in FOLIO (For CUL, this is the user's NetId)
      #
      # Return:
      # A hash containing:
      # +:user+:: A FOLIO user's record, or nil
      # +:code+:: An HTTP response code
      # +:error+:: An error message, or nil
      ##
      def self.patron_record(okapi, tenant, token, username)
        url = "#{okapi}/users?query=(username==#{username})"
        headers = {
          "X-Okapi-Tenant" => tenant,
          "x-okapi-token" => token,
          :accept => "application/json",
        }
        return_value = {
          :user => nil,
          :error => nil,
        }
        begin
          response = RestClient.get(url, headers)
          # Convert from JSON to hash (JSON is in the form
          # {'users': [array of users], 'totalRecords', 'resultInfo': {}})
          results = JSON.parse(response.body)
          users = results["users"]
          if users.count == 1
            return_value[:user] = users[0]
            return_value[:code] = response.code
          else
            return_value[:code] = 500
            return_value[:error] = 'Could\'nt find user record'
          end
        rescue RestClient::ExceptionWithResponse => err
          return_value[:code] = err.response.code
          return_value[:error] = err.response.body
        end
        return return_value
      end
      ##
      # Connects to an Okapi instance and uses the +/patron/account+ endpoint
      # from the +edge-patron+ module to retrieve a user's account information
      #
      # Params:
      # +okapi+:: URL of an okapi instance (e.g., "https://folio-snapshot-okapi.dev.folio.org")
      # +tenant+:: An Okapi tenant ID
      # +token+:: An Okapi token string from a previous authentication call
      # +identifiers+:: A hash containing either a +:folio_id+ string (a FOLIO user's UUID)
      # or a +:username+ string (a FOLIO user's username)
      #
      # Return:
      # A hash containing:
      # +:account+:: A user's account information hash, or nil
      # +:code+:: An HTTP response code
      # +:error+:: An error message, or nil
      ##
      def self.patron_account(okapi, tenant, token, identifiers)
        folio_id = identifiers[:folio_id]
        if folio_id.nil?
          # TODO: Add error checking here -- :username could be blank, or the return from
          # patron_uuid could fail
          response = self.patron_record(okapi, tenant, token, identifiers[:username])
          if response[:code] < 300
            folio_id = response[:user]["id"]
          else
            # We don't have an identifier for the user, so there's no point in continuing
            return {
                     :account => nil,
                     :code => 500,
                     :error => 'Couldn\'t identify user',
                   }
          end
        end
        url = "#{okapi}/patron/account/#{folio_id}?includeLoans=true&includeHolds=true&includeCharges=true"
        headers = {
          "X-Okapi-Tenant" => tenant,
          "x-okapi-token" => token,
          :accept => "application/json",
        }
        return_value = {
          :account => nil,
          :error => nil,
        }
        begin
          response = RestClient.get(url, headers)
          return_value[:account] = JSON.parse(response.body)
          return_value[:code] = response.code
        rescue RestClient::ExceptionWithResponse => err
          return_value[:code] = err.response.code
          return_value[:error] = err.response.body
        end
        return return_value
      end
      ##
      # Connects to an Okapi instance and uses the +/patron/account+ endpoint
      # from the +edge-patron+ module to renew an item
      #
      # Params:
      # +okapi+:: URL of an okapi instance (e.g., "https://folio-snapshot-okapi.dev.folio.org")
      # +tenant+:: An Okapi tenant ID
      # +token+:: An Okapi token string from a previous authentication call
      # +userId+:: A FOLIO user username
      # +itemId+:: A FOLIO item UUID
      #
      # Return:
      # A hash containing:
      # +:due_date+:: The new item due date, or nil
      # +:code+:: An HTTP response code
      # +:error+:: An error message, or nil
      ##
      def self.renew_item(okapi, tenant, token, username, itemId)
        userId = self.patron_record(okapi, tenant, token, username)[:user]["id"]
        # TODO: Add error checking here -- :username could be blank, or the return from
        # patron_uuid could fail
        url = "#{okapi}/patron/account/#{userId}/item/#{itemId}/renew"
        headers = {
          "X-Okapi-Tenant" => tenant,
          "x-okapi-token" => token,
          :accept => "application/json",
        }
        return_value = {
          :due_date => nil,
          :error => nil,
        }
        begin
          response = RestClient.post(url, {}, headers)
          return_value[:code] = response.code
          return_value[:due_date] = JSON.parse(response.body)["dueDate"]
        rescue RestClient::ExceptionWithResponse => err
          return_value[:code] = err.response.code
          return_value[:error] = JSON.parse(err.response.body)
        end
        return return_value
      end
    end
  end
end
