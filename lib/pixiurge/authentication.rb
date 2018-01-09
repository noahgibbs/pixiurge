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
# authentication. If you care a lot about it, may I recommend rolling
# your own? At a minimum, it's very easy to need better account
# storage than the default built-in version.
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
# {Pixiurge::App#handle_message} and you receive an authorization
# message.
#
# @see Pixiurge::App
# @since 0.1.0
class Pixiurge::AuthenticatedApp < Pixiurge::App
  # Regex for what usernames are allowed
  USERNAME_REGEX = /\A[a-zA-Z0-9]+\Z/

  # Constructor
  #
  # @param options [Hash] Options for the app
  # @option options [String] accounts_file JSON file to hold the accounts. Defaults to "accounts.json".
  # @option options [Pixiurge::Authentication::AccountStorage] storage An object to hold the accounts matching the AccountStorage interface
  # @return [void]
  # @since 0.1.0
  def initialize(options = { "accounts_file" => "accounts.json" })
    @storage = options["storage"] || Pixiurge::Authentication::FileAccountStorage.new(options["accounts_file"] || "accounts.json")
    nil
  end

  # Process an authorization message.
  #
  # @see #on_message
  # @param websocket [Websocket] A websocket object, as defined by the websocket-driver gem
  # @param msg_type [String] The message type - not "auth", which has already been stripped off, but the subtype
  # @param args [Array] Additional message-type-specific arguments
  # @return [void]
  # @since 0.1.0
  def on_auth_message(websocket, msg_type, *args)
    if msg_type == Pixiurge::Protocol::Incoming::AUTH_REGISTER_ACCOUNT
      username, salt, hashed = args[0]["username"], args[0]["salt"], args[0]["bcrypted"]
      user_state = @storage.data_for(username)
      if user_state
        return websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_FAILED_REGISTRATION, { "message" => "Account #{username.inspect} already exists!" }
      end
      unless username =~ USERNAME_REGEX
        return websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_FAILED_REGISTRATION, { "message" => "Username contains illegal characters: #{username.inspect}!" }
      end
      @storage.register(username, { "account" => { "salt" => salt, "hashed" => hashed, "method" => "bcrypt" } })
      websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_REGISTRATION, { "username" => username }

      return
    end

    if msg_type == Pixiurge::Protocol::Incoming::AUTH_LOGIN
      username, hashed = args[0]["username"], args[0]["bcrypted"]
      user_state = @storage.data_for(username)
      unless user_state
        return websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_FAILED_LOGIN, { "message" => "No such user as #{username.inspect}!" }
      end
      if user_state["account"]["hashed"] == hashed
        # Let the browser side know that a login succeeded
        websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_LOGIN, { "username" => username }
        # Let the app know that a login succeeded
        self.on_login(websocket, username) if self.respond_to?(:on_login)
        return
      else
        return websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_FAILED_LOGIN, { "message" => "Wrong password for user #{username.inspect}!" }
      end
      # Unreachable, already returned
    end

    if msg_type == Pixiurge::Protocol::Incoming::AUTH_GET_SALT
      username = args[0]["username"]
      user_state = @storage.data_for(username)
      unless user_state
        return websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_FAILED_LOGIN, { "message" => "No such user as #{username.inspect}!" }
      end
      user_salt = user_state["account"]["salt"]
      return websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_SALT, { "salt" => user_salt }
    end

    raise "Unrecognized authorization message: #{msg_type.inspect} / #{args.inspect}!"
  end
end

# Code specific to Pixiurge's built-in Authentication libraries.
#
# @since 0.1.0
module Pixiurge::Authentication; end

# This stores a collection of Pixiurge accounts. If you want to store
# accounts in a nonstandard way, this is the interface to match -
# inheritance could be a useful way to do it, but duck-typing is fine
# too. You can pass a {Pixiurge::Authentication::AccountStorage} into
# the constructor for a {Pixiurge::AuthenticatedApp}.
#
# @since 0.1.0
class Pixiurge::Authentication::AccountStorage
  # Create an account. The account_data hash will contain information
  # about the encrypted password hash in the default setup, but it's
  # allowed to contain any JSON-serializable Hash in general.
  #
  # @param username [String] The account's username; see AuthenticatedApp::USERNAME_REGEX for legal format
  # @param account_data [Hash{String}] The user's data, normally including login info
  # @return [void]
  # @since 0.1.0
  def register(username, account_data)
    raise "Override register to create a valid AccountStorage object!"
  end

  # Get user data for the named account.
  #
  # @param username [String] The account's username
  # @return [Hash{String=>String}] The account's user data
  # @since 0.1.0
  def data_for(username)
    raise "Override data_for to create a valid AccountStorage object!"
  end

  # Set user data for the named account. Any fields not included in
  # the new value are deleted.
  #
  # @param username [String] The account's username
  # @param new_data [Hash{String=>String}] The account's new user data
  # @return [void]
  # @since 0.1.0
  def set_data_for(username, new_data)
    raise "Override set_data_for to create a valid AccountStorage object!"
  end

  # Unregister the named account; delete it from the AccountStorage.
  #
  # @param username [String] The account's username
  # @return [void]
  # @since 0.1.0
  def unregister(username)
    raise "Override unregister to create a valid AccountStorage object!"
  end
end

# Store account data as a JSON file. Not multithread-safe. This is the
# default built-in account storage if you don't specify.
#
# @since 0.1.0
class Pixiurge::Authentication::FileAccountStorage < Pixiurge::Authentication::AccountStorage
  # Constructor
  #
  # @since 0.1.0
  def initialize(pathname, oldpathname = pathname + ".old")
    @accounts_json_filename = pathname
    @accounts_old_json_filename = oldpathname

    sync_account_state
  end

  # Create an account. The account_data hash will contain information
  # about the encrypted password hash in the default setup, but it's
  # allowed to contain any JSON-serializable Hash in general.
  #
  # @param username [String] The account's username; see AuthenticatedApp::USERNAME_REGEX for legal format
  # @param account_data [Hash{String}] The user's data, normally including login info
  # @return [void]
  # @since 0.1.0
  def register(username, account_data)
    @account_state[username] = account_data
    sync_account_state
  end

  # Get user data for the named account.
  #
  # @param username [String] The account's username
  # @return [Hash{String=>String},nil] The account's user data or nil if it does not exist
  # @since 0.1.0
  def data_for(username)
    @account_state[username]
  end

  # Set user data for the named account. Any fields not included in
  # the new value are deleted. Raise an error if the username does not
  # exist.
  #
  # @param username [String] The account's username
  # @param new_data [Hash{String=>String}] The account's new user data
  # @return [void]
  # @since 0.1.0
  def set_data_for(username, new_data)
    @account_state[username] = new_data
    sync_account_state
  end

  # Unregister the named account; delete it from the AccountStorage.
  #
  # @param username [String] The account's username
  # @return [void]
  # @since 0.1.0
  def unregister(username)
    unless @account_state[username]
      raise "No such account username as #{username.inspect}!"
    end
    @account_state.delete(username)
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

end

# Store account data as a Hash in memory. Does not persist across
# reboots. This is intended for testing, not production.
#
# @since 0.1.0
class Pixiurge::Authentication::MemStorage < Pixiurge::Authentication::AccountStorage
  # Only for testing, but then so is this storage method
  attr_reader :account_state

  # Constructor
  #
  # @since 0.1.0
  def initialize
    @account_state = {}
  end

  # Create an account. The account_data hash will contain information
  # about the encrypted password hash in the default setup, but it's
  # allowed to contain any JSON-serializable Hash in general.
  #
  # @param username [String] The account's username; see AuthenticatedApp::USERNAME_REGEX for legal format
  # @param account_data [Hash{String}] The user's data, normally including login info
  # @return [void]
  # @since 0.1.0
  def register(username, account_data)
    @account_state[username] = account_data
  end

  # Get user data for the named account.
  #
  # @param username [String] The account's username
  # @return [Hash{String=>String},nil] The account's user data or nil if it does not exist
  # @since 0.1.0
  def data_for(username)
    @account_state[username]
  end

  # Set user data for the named account. Any fields not included in
  # the new value are deleted. Raise an error if the username does not
  # exist.
  #
  # @param username [String] The account's username
  # @param new_data [Hash{String=>String}] The account's new user data
  # @return [void]
  # @since 0.1.0
  def set_data_for(username, new_data)
    @account_state[username] = new_data
  end

  # Unregister the named account; delete it from the AccountStorage.
  #
  # @param username [String] The account's username
  # @return [void]
  # @since 0.1.0
  def unregister(username)
    unless @account_state[username]
      raise "No such account username as #{username.inspect}!"
    end
    @account_state.delete(username)
  end

end
