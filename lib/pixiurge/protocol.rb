# This file records the specifics of Pixiurge's JSON wire protocol, both incoming and outgoing.

# Constants and code for Pixiurge client-server protocol handling.
#
# @since 0.1.0
module Pixiurge::Protocol; end

# Fixed constants for incoming protocol messages. "Incoming" in this
# sense means "sent from the front end to the server" rather than
# vice-versa.
#
# @since 0.1.0
module Pixiurge::Protocol::Incoming
  # This is the JSON specifier for registering an account using the
  # built-in auth protocol. If used, it's the second string entry in
  # its JSON array. The final entry in the array is a
  # Hash{String=>String} with the keys "username", "salt" and
  # "bcrypted".
  #
  # @since 0.1.0
  AUTH_REGISTER_ACCOUNT = "register_account"

  # This is the JSON specifier for logging into an account using the
  # built-in auth protocol. If used, it's the second string entry in
  # its JSON array. The final entry in the array is a
  # Hash{String=>String} with the keys "username" and "bcrypted".
  # Note that the bcrypted value implicitly uses the salt, which does
  # not need to be explicitly sent to the server - BCrypt handles
  # that.
  #
  # @since 0.1.0
  AUTH_LOGIN = "hashed_login"

  # This is the JSON specifier for logging getting an account's
  # cryptographic salt using the built-in auth protocol. If used, it's
  # the second string entry in its JSON array. The final entry in the
  # array is a Hash{String=>String} with the key "username".
  #
  # @since 0.1.0
  AUTH_GET_SALT = "get_salt"
end

# Fixed constants for outgoing protocol messages. That means messages
# sent from the server to the front end rather than the opposite.
#
# @since 0.1.0
module Pixiurge::Protocol::Outgoing

  # This is the JSON message type for a failed registration in the
  # built-in AuthenticatedApp's protocol. It is an initial string in
  # its JSON array. There is a Hash{String=>String} following in the
  # same message. The key "message" holds a human-readable reason for
  # the failure.
  #
  # @since 0.1.0
  AUTH_FAILED_REGISTRATION = "failed_registration"

  # This is the JSON message type for a failed login in the built-in
  # AuthenticatedApp's protocol. It is an initial string in its JSON
  # array. There is a Hash{String=>String} following in the same
  # message. The key "message" holds a human-readable reason for the
  # failure. This message is also sent when getting the user's salt
  # fails, usually because no such user exists.
  #
  # @since 0.1.0
  AUTH_FAILED_LOGIN = "failed_login"

  # This is the JSON message type for a successful registration in the
  # built-in AuthenticatedApp's protocol. It is an initial string in
  # its JSON array. The second member of the JSON array is a hash with
  # the key "username" with the account username as the value.
  #
  # @since 0.1.0
  AUTH_REGISTRATION = "registration"

  # This is the JSON message type for a successful login in the
  # built-in AuthenticatedApp's protocol. It is an initial string in
  # its JSON array. The second member of the JSON array is a hash with
  # the key "username" with the account username as the value.
  #
  # @since 0.1.0
  AUTH_LOGIN = "login"

  # This is the JSON message type for a successful query of the salt
  # in the built-in AuthenticatedApp's protocol. It is an initial
  # string in its JSON array. The second member of the JSON array is a
  # hash with the key "salt" with the account's salt as the value.
  #
  # @since 0.1.0
  AUTH_SALT = "login_salt"

  # This is the message used to set up an initial display with
  # appropriate settings. It should normally never be sent a second
  # time. This should contain display-relevant and server-variable
  # settings like how fast in milliseconds a tick is.
  #
  # @since 0.1.0
  DISPLAY_INIT = "display_init"

  # This message tells the client to load a JSON spritesheet by name
  # as an asset. By passing the asset name (not the full asset), this
  # slows down initial loading from an empty cache but speeds up
  # future cached requests - it's hard to cache or compress assets
  # that are sent inside Websocket messages.
  #
  # @since 0.1.0
  LOAD_SPRITESHEET = "display_load_spritesheet"

  # This message tells the client a spritesheet is no longer in use.
  #
  UNLOAD_SPRITESHEET = "display_unload_spritesheet"

  # This message tells the client to load and display a spritestack by
  # name as an asset. By passing the asset name (not the full asset),
  # this slows down initial loading from an empty cache but speeds up
  # future cached requests - it's hard to cache or compress assets
  # that are sent inside Websocket messages.
  #
  # @since 0.1.0
  LOAD_SPRITESTACK = "display_load_spritestack"

  # This message tells the client a spritestack is no longer in use
  # and should be visually hidden and removed.
  #
  UNLOAD_SPRITESTACK = "display_unload_spritesheet"

end
