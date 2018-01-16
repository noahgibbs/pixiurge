# Pixiurge::AuthenticatedApp is a parent class for applications
# (games) that want the built-in Pixiurge accounts and
# authentication.
#
# AuthenticatedApp only allows a single login by each player at one
# time. That's not a hard limit of Pixiurge, but AuthenticatedApp
# requires it. Similarly, AuthenticatedApp adds the requirement that
# you register an account for each player before logging in.
#
# For more details of how to implement on top of it, see
# {Pixiurge::AppInterface}.
#
# ### Implementation
#
# It's not terribly hard to roll your own authentication system in
# Ruby. It is *easy* to make something horrifically insecure any time
# you're doing browser/server communication. Pixiurge makes this
# neither harder nor easier than usual. The built-in authentication is
# simple and pretty okay *if* you keep the requirement for HTTPS/WSS
# for messages. If you use this over an unencrypted connection, all
# your password-equivalents can be stolen for your game, but it
# shouldn't leak the actual passwords -- passwords are never sent to
# the server, though they are preserved unencrypted in browser
# cookies.
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
# @see Pixiurge::AppInterface
# @since 0.1.0
class Pixiurge::AuthenticatedApp < Pixiurge::App
  # Regex for what usernames are allowed
  USERNAME_REGEX = /\A[a-zA-Z0-9]+\Z/

  # Constructor
  #
  # @param options [Hash] Options to configure app behavior
  # @option options [String] accounts_file JSON file to hold the accounts. Defaults to "accounts.json".
  # @option options [Pixiurge::Authentication::AccountStorage] storage An object to hold the accounts matching the AccountStorage interface
  # @option options [Boolean] debug Whether to print debug output
  # @option options [Boolean] record_traffic Whether to record incoming and outgoing websocket traffic to logfiles
  # @option options [String] incoming_traffic_logfile Pathname to record incoming websocket traffic
  # @option options [String] outgoing_traffic_logfile Pathname to record outgoing websocket traffic
  # @return [void]
  # @since 0.1.0
  def initialize(options = { "debug" => false, "record_traffic" => false,
                   "incoming_traffic_logfile" => "log/incoming_traffic.json", "outgoing_traffic_logfile" => "log/outgoing_traffic.json",
                   "accounts_file" => "accounts.json" })
    super
    @storage = options["storage"] || Pixiurge::Authentication::FileAccountStorage.new(options["accounts_file"] || "accounts.json")
    @username_for_websocket = {}
    @websocket_for_username = {}
    nil
  end

  # Process an authorization message or fall back to old message handling.
  #
  # @see #on_message
  # @param websocket [Websocket] A websocket object, as defined by the websocket-driver gem
  # @param args [Array] Additional message-type-specific arguments
  # @return [void]
  # @since 0.1.0
  def handle_message(websocket, args)
    msg_type = args[0]
    if msg_type == Pixiurge::Protocol::Incoming::AUTH_REGISTER_ACCOUNT
      username, salt, hashed = args[1]["username"], args[1]["salt"], args[1]["bcrypted"]
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
      username, hashed = args[1]["username"], args[1]["bcrypted"]
      user_state = @storage.data_for(username)
      unless user_state
        return websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_FAILED_LOGIN, { "message" => "No such user as #{username.inspect}!" }
      end
      if user_state["account"]["hashed"] == hashed
        # Let the browser side know that a login succeeded
        websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_LOGIN, { "username" => username }
        # Let the app know that a login succeeded
        return send_event "login", websocket, username
      else
        return websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_FAILED_LOGIN, { "message" => "Wrong password for user #{username.inspect}!" }
      end
      # Unreachable, already returned
    end

    if msg_type == Pixiurge::Protocol::Incoming::AUTH_GET_SALT
      username = args[1]["username"]
      user_state = @storage.data_for(username)
      unless user_state
        return websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_FAILED_LOGIN, { "message" => "No such user as #{username.inspect}!" }
      end
      user_salt = user_state["account"]["salt"]
      return websocket_send websocket, Pixiurge::Protocol::Outgoing::AUTH_SALT, { "salt" => user_salt }
    end

    super
  end

  # If you inherit from AuthenticatedApp, this handler will be called
  # when a player has successfully logged in. Later handlers will
  # continue passing the websocket object. This handler lets you
  # associate the websocket with a specific player account. If you
  # override this method, make sure to call super() so that the
  # AuthenticatedApp code can implement methods like
  # {Pixiurge::AuthenticatedApp#username_for_websocket}.
  #
  # @param ws [Websocket] A Websocket-Driver websocket object
  # @param username [String] The username for the account
  # @return [void]
  # @since 0.1.0
  def on_login(ws, username)
    reconnect = false

    # This websocket is already logged in. Weird. Close the new connection.
    if @username_for_websocket.has_key?(ws)
      websocket_send ws, Pixiurge::Protocol::Outgoing::AUTH_FAILED_LOGIN, { "message" => "Your websocket is somehow already logged in! Failing!" }
      ws.close(1002, "Websocket already logged in, failing")  # 1002 is a protocol error, such as a double-login
      return
    end

    # This username is already logged in, so we'll override. Close the old connection.
    if @websocket_for_username.has_key?(username)
      old_ws = @websocket_for_username[username]
      websocket_send old_ws, Pixiurge::Protocol::Outgoing::DISCONNECTION, { "message" => "You have just logged in from a new location - disconnecting your old location." }
      old_ws.close(1000, "You have been disconnected in favor of a new connection by your account.")
      @username_for_websocket.delete(old_ws)
      reconnect = true
    end

    @username_for_websocket[ws] = username
    @websocket_for_username[username] = ws

    if reconnect
      send_event "player_reconnect", username
    else
      send_event "player_login", username
    end
    nil
  end

  # This handler will be called when a websocket connection is
  # closed. It can be used for cleaning up player-related data
  # structures.
  #
  # @param ws [#on] A Websocket-Driver websocket object
  # @param code [Integer] A Websocket protocol onclose status code (see https://tools.ietf.org/html/rfc6455)
  # @param reason [String] A reason for the websocket closing
  # @return [void]
  # @since 0.1.0
  def on_close(ws, code, reason)
    username = @username_for_websocket.delete(ws)
    if username && @websocket_for_username[username] == ws
      @websocket_for_username.delete(username)
      send_event "player_logout", username
    end
    nil
  end

  # For a given websocket object, get its associated username.
  #
  # @param websocket [Websocket] The Websocket object to query
  # @return [String,nil] The username for this websocket or nil if there is none currently
  # @since 0.1.0
  def username_for_websocket(websocket)
    @username_for_websocket[websocket]
  end

  # For a given account username, get its associated websocket if any.
  #
  # @param websocket [String] The account username to query
  # @return [Websocket,nil] The websocket for this account if it's logged in, or nil if not
  # @since 0.1.0
  def websocket_for_username(websocket)
    @websocket_for_username[websocket]
  end

  # Return a list of all currently connected usernames.
  #
  # @return [Array<String>] Usernames for all connected accounts.
  # @since 0.1.0
  def all_logged_in_usernames
    @username_for_websocket.keys
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
