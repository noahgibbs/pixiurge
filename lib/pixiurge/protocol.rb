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
  # Register an account using the built-in auth protocol.
  #
  # @example [ AUTH_REGISTER_ACCOUNT, { "username" => username, "salt" => salt, "bcrypted" => hash } ]
  #
  # @since 0.1.0
  AUTH_REGISTER_ACCOUNT = "register_account"

  # Log into an account using the built-in auth protocol. If used,
  # it's the second string entry in its JSON array.  Note that the
  # bcrypted value implicitly uses the salt, which does not need to be
  # explicitly sent to the server. BCrypt handles that part.
  #
  # @example [ AUTH_LOGIN, { "username" => username, "bcrypted" => hash } ]
  #
  # @since 0.1.0
  AUTH_LOGIN = "hashed_login"

  # Get an account's cryptographic salt for the built-in auth
  # protocol.
  #
  # @example [ AUTH_GET_SALT, { "username" => username } ]
  #
  # @since 0.1.0
  AUTH_GET_SALT = "get_salt"

  module Keycode
    # This is the ASCII and web-browser keycode for the left arrow.
    #
    # @since 0.1.0
    LEFT_ARROW = 37

    # This is the ASCII and web-browser keycode for the up arrow.
    #
    # @since 0.1.0
    UP_ARROW = 38

    # This is the ASCII and web-browser keycode for the right arrow.
    #
    # @since 0.1.0
    RIGHT_ARROW = 39

    # This is the ASCII and web-browser keycode for the down arrow.
    #
    # @since 0.1.0
    DOWN_ARROW = 40
  end
end

# Fixed constants for outgoing protocol messages. That means messages
# sent from the server to the front end rather than the opposite.
#
# @since 0.1.0
module Pixiurge::Protocol::Outgoing

  # Failed registration in the built-in AuthenticatedApp's
  # protocol. The key "message" holds a human-readable reason for the
  # failure.
  #
  # @example [ AUTH_FAILED_REGISTRATION, { "message" => "That name already exists" } ]
  #
  # @since 0.1.0
  AUTH_FAILED_REGISTRATION = "failed_registration"

  # Failed login or failure to get login information in the built-in
  # AuthenticatedApp's protocol. The key "message" holds a
  # human-readable reason for the failure. This message is sent when
  # getting the user's salt fails, usually because no such user
  # exists.
  #
  # @example [ AUTH_FAILED_LOGIN, { "message" => "Wrong password" } ]
  #
  # @since 0.1.0
  AUTH_FAILED_LOGIN = "failed_login"

  # Successful registration in the built-in AuthenticatedApp's
  # protocol.
  #
  # @example [ AUTH_REGISTRATION, { "username" => username } ]
  #
  # @since 0.1.0
  AUTH_REGISTRATION = "registration"

  # Successful login in the built-in AuthenticatedApp's protocol.
  #
  # @example [ AUTH_LOGIN, { "username" => username } ]
  #
  # @since 0.1.0
  AUTH_LOGIN = "login"

  # Successful query of the salt in the built-in AuthenticatedApp's
  # protocol.
  #
  # @example [ AUTH_SALT, { "salt" => cryptographic_salt } ]
  #
  # @since 0.1.0
  AUTH_SALT = "login_salt"

  # Let the front end know that the socket is being intentionally
  # disconnected. Possible reasons include a user request to
  # disconnect, another login from the same account or an
  # administrator requesting the disconnect. After the message type,
  # there is a hash argument. The "message" key holds a human-readable
  # message with the reason for the disconnection.
  #
  # @example [ DISCONNECTION, { "message" => "Administrator has blocked this IP address." } ]
  #
  # @since 0.1.0
  DISCONNECTION = "disconnect"

  # Set up an initial display with appropriate settings. It should
  # normally never be sent a second time on the same connection. The
  # final hash should contain display-relevant and server-variable
  # settings like how fast in milliseconds a tick is.
  #
  # @example [ DISPLAY_INIT, { "ms_per_tick" => 300, "height" => 256, "width" => 256 } ]
  #
  # @since 0.1.0
  DISPLAY_INIT = "display_init"

  # All currently shown displayables of any description should be
  # hidden. Items, agents, locations and effects are all removed,
  # animations should be cancelled and any hints or preloads no longer
  # apply.
  #
  # @example [ DISPLAY_DESTROY_ALL ]
  #
  # @since 0.1.0
  DISPLAY_DESTROY_ALL = "display_destroy_all"

  # Destroy a single Displayable by name.
  #
  # @example [ DISPLAY_DESTROY_DISPLAYABLE, "item name" ]
  #
  # @since 0.1.0
  DISPLAY_DESTROY_DISPLAYABLE = "display_destroy"

  # Show a Displayable object. The arguments following the message
  # type are a String name for the item and then a Hash of additional
  # details, such as the URL for a TMX item.
  #
  # @example [ DISPLAY_SHOW_DISPLAYABLE, "my room", { "type" => "tmx", "url" => "tmx/my_room_map.json" } ]
  #
  # @since 0.1.0
  DISPLAY_SHOW_DISPLAYABLE = "display_show"

  # Move a Displayable object within a location. The arguments that
  # follow are the Displayable's name, then a hash with the keys
  # "old_position", "position" and "options".
  #
  # @example [ DISPLAY_MOVE_DISPLAYABLE, "item name", { "old_position" => "location_name#23,4", "position" => "location_name#23,5", "options" => { "locomotion" => "brachiating" } } ]
  #
  # @since 0.1.0
  DISPLAY_MOVE_DISPLAYABLE = "display_move"

  # Pan the viewpoint's center to the pixel offset given.
  #
  # @example [ DISPLAY_PAN_TO_PIXEL, item_name, x_pixel, y_pixel, options ]
  #
  # @since 0.1.0
  DISPLAY_PAN_TO_PIXEL = "display_pan"
end
