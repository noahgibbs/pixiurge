module Pixiurge
  # Pixiurge has a set of specific notifications that it sends via the
  # Demiurge (simulation) notification system.  Like the Demiurge core
  # notifications in #{Demiurge::Notifications}, these are defined in
  # a module with constants.
  #
  # @since 0.1.0
  module Notifications
    # This occurs when a player logs in. It is in addition to any
    # relevant NewItem or MoveTo notifications that may occur as a
    # result.
    #
    # @since 0.1.0
    PlayerLogin = "player_login"

    # This occurs when a player logs out. It is in addition to any
    # relevant MoveTo or item destruction notifications.
    #
    # @since 0.1.0
    PlayerLogout = "player_logout"

    # This occurs when a player reconnects. A reconnect event won't
    # usually result in the player's body changing significantly, and
    # is often effectively a non-event.
    #
    # @since 0.1.0
    PlayerReconnect = "player_reconnect"
  end
end
