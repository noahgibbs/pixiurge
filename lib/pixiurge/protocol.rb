# This file records the specifics of Pixiurge's JSON wire protocol, both incoming and outgoing.

# Constants and code for Pixiurge client-server protocol handling.
#
# @since 0.1.0
module Pixiurge::Protocol; end

# Fixed constants for incoming protocol messages
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

# Fixed constants for outgoing protocol messages
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
end
