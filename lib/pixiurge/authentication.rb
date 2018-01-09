# Pixiurge::AuthenticatedApp is a parent class for applications
# (games) that want the built-in Pixiurge accounts and
# authentication. It's not terribly hard to roll your own as
# authentication systems go, but it *is* easy to make something
# horrifically insecure any time you're doing browser/server
# communication.  Pixiurge makes this neither harder nor easier than
# usual. The built-in authentication is simple and pretty okay *if*
# you keep the requirement for HTTPS/WSS for messages. If you use this
# over an unencrypted connection, all your password-equivalents can be
# stolen for your game, but it shouldn't leak the actual passwords --
# passwords are never sent to the server, though they are preserved
# unencrypted in browser cookies.
#
# There are lots of potential ways to implements accounts and
# authentication. I suspect in the long term it will be one or more
# modules rather than a parent class. Or perhaps some combination of
# the two.
#
# The built-in authentication and accounts class makes several
# simplifying assumptions. Accounts are held in a JSON
# file. Client-side BCrypt is used to slow attackers trying to
# brute-force a password, and to keep rainbow tables from helping
# significantly. We assume all exchange of messages is done over HTTPS
# and/or WSS, which means that TLS/SSL encryption keeps the
# client-side BCrypted key from acting as a simple reusable token.
#
# This works fine for now, but is intentionally easy to replace or
# modify if needed later. It would be reasonable to store passwords in
# a database, for instance.  One caveat: passwords should *not* be
# stored in the Engine data, because we don't want various types of
# rollbacks to affect them, nor do we want in-game administrators to
# easily query them. The latter is hard to ensure, but it's still
# better not to put them directly in the in-engine data.
#
# This class defines the method {#on_auth_message}. If you inherit
# from the class, make sure to call super if you override
# {#on_auth_message}, or call {#on_auth_message} if you override
# {#on_message} and you receive an authorization message.
#
# @since 0.1.0
class Pixiurge::AuthenticatedApp < Pixiurge::App
  # Regex for what usernames are allowed
  USERNAME_REGEX = /\A[a-zA-Z0-9]+\Z/

  # Constructor
  #
  # @param options [Hash] Options for the app
  # @option options [String] accounts_file JSON file to hold the accounts. Defaults to "accounts.json".
  # @since 0.1.0
  def initialize(options = { "accounts_file" => "accounts.json" })
    @accounts_json_filename = options["accounts_file"] || "accounts.json"
    @accounts_old_json_filename = @accounts_json_filename + ".old"

    sync_account_state
  end

  private

  def sync_account_state
    unless @account_state
      if File.exist?(@accounts_json_filename)
        @account_state = MultiJson.load(File.read @accounts_json_filename)
      else
        @account_state = {}
      end
    end

    if File.exist?(@accounts_json_filename)
      FileUtils.mv @accounts_json_filename, @accounts_old_json_filename
    end
    File.open(@accounts_json_filename, "w") do |f|
      f.write MultiJson.dump(@account_state, :pretty => true)
    end
  end

  public

  # Process an authorization message.
  #
  # @see #on_message
  # @param websocket [Websocket] A websocket object, as defined by the websocket-driver gem
  # @param msg_type [String] The message type - not "auth", which has already been stripped off, but the subtype
  # @param args [Array] Additional message-type-specific arguments
  # @return [void]
  # @since 0.1.0
  def on_auth_message(websocket, msg_type, *args)
    sync_account_state

    if msg_type == Pixiurge::Protocol::Incoming::AUTH_REGISTER_ACCOUNT
      username, salt, hashed = args[0]["username"], args[0]["salt"], args[0]["bcrypted"]
      if @account_state[username]
        return websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_FAILED_REGISTRATION, { "message" => "Account #{username.inspect} already exists!" }
      end
      unless username =~ USERNAME_REGEX
        return websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_FAILED_REGISTRATION, { "message" => "Username contains illegal characters: #{username.inspect}!" }
      end
      @account_state[username] = { "account" => { "salt" => salt, "hashed" => hashed, "method" => "bcrypt" } }
      sync_account_state
      websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_REGISTRATION, { "username" => username }

      return
    end

    if msg_type == Pixiurge::Protocol::Incoming::AUTH_LOGIN
        username, hashed = args[0]["username"], args[0]["bcrypted"]
        unless @account_state[username]
          return websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_FAILED_LOGIN, { "message" => "No such user as #{username.inspect}!" }
        end
        if @account_state[username]["account"]["hashed"] == hashed
          # Let the browser side know that a login succeeded
          websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_LOGIN, { "username" => username }
          # Let the app know that a login succeeded
          return self.on_login(websocket, username)
        else
          return websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_FAILED_LOGIN, { "message" => "Wrong password for user #{username.inspect}!" }
        end
      # Unreachable, already returned
    end

    if msg_type == Pixiurge::Protocol::Incoming::AUTH_GET_SALT
      username = args[0]["username"]
      unless @account_state[username]
        return websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_FAILED_LOGIN, { "message" => "No such user as #{username.inspect}!" }
      end
      user_salt = @account_state[username]["account"]["salt"]
      return websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_SALT, { "salt" => user_salt }
    end

    raise "Unrecognized authorization message: #{msg_data.inspect}!"
  end
end
