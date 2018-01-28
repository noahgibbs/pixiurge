# Here's an example of the kind of Ruby extension that you might keep
# in your World Files.  This lets you call "player_state" inside any
# player action to store information inside the player's state in the
# simulated world.
#
# You wouldn't make this part of Pixiurge or Demiurge because it
# depends on a specific InertStateItem called "player", which you'll
# find in the admin zone file. But it's a convenient little extension
# to the way the World Files work and show how you want to do it in
# your own game -- you can remove this file if it *isn't* how you want
# to do it.
class Demiurge::ActionItemInternal::AgentBlockRunner
  # This returns a block of player-specific state which can be used
  # for settings.
  def player_state
    return unless item.state["player"]  # Only allow setting player state in a player agent's block runner.

    player_item = engine.item_by_name("players")
    player_item.state[item.state["player"]] ||= {}  # Allocate player settings for this player name
  end
end
