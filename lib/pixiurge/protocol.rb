# This file records the specifics of Pixiurge's JSON wire protocol, both incoming and outgoing.

# Constants and code for Pixiurge client-server protocol handling.
#
# @since 0.1.0
module Pixiurge::Protocol; end

# Fixed constants for incoming protocol messages
#
# @since 0.1.0
module Pixiurge::Protocol::Incoming
  # This is the JSON header for an incoming authorization message. It's the first entry in its array.
  #
  # @since 0.1.0
  AUTH_MSG_TYPE = "auth"

  # This is the JSON header for an incoming player-action message. It's the first entry in its array.
  #
  # @since 0.1.0
  ACTION_MSG_TYPE = "act"
end

# Fixed constants for outgoing protocol messages
#
# @since 0.1.0
module Pixiurge::Protocol::Outgoing
end
