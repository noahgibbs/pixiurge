module Pixiurge
  # Pixiurge has a set of specific notifications that it sends via the
  # Demiurge (simulation) notification system.  Like the Demiurge core
  # notifications in #{Demiurge::Notifications}, these are defined in
  # a module with constants.
  module Notifications
    # This occurs when a player logs in. It is in addition to any
    # relevant NewItem or MoveTo notifications that may occur as a
    # result.
    PlayerLogin = "player_login"

    # This occurs when a player logs out. It is in addition to any
    # relevant MoveTo or item destruction notifications.
    PlayerLogout = "player_logout"

    # This occurs when a player reconnects. A reconnect event won't
    # usually result in the player's body changing significantly, and
    # is often effectively a non-event.
    PlayerReconnect = "player_reconnect"
  end
end
