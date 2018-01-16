require "pixiurge/displayable"

# A TmxMap uses a Demiurge item's TMX entry as its source of data and
# behavior.
#
# @since 0.1.0
class Pixiurge::Display::TmxMap < ::Pixiurge::Displayable
  # Constructor. Assume we read the TMX cache information from the Demiurge item and display it.
  #
  # @since 0.1.0
  def initialize(demi_item:, name:, engine_connector:)
    super
    @entry = @demi_item.tile_cache_entry
    @block_width = @entry["tilewidth"]
    @block_height = @entry["tileheight"]
  end

  # Send messages to display the TMX object.
  #
  # @param player [Pixiurge::Player] The player to show this Displayable to
  # @return [void]
  # @since 0.1.0
  def show_to_player(player)
    player.message Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_TMX, @name, File.join(@entry["dir"], @entry["tmx_name"] + ".json")
    nil
  end

  # Animate the motion of this Displayable from an old location to a
  # new location for the stated player. This will be handled by the
  # EngineConnector, usually as part of showing various things to
  # multiple players.
  #
  # When doing an animation or other transition, it's important to
  # specify the older and newer coordinates. This can't easily use
  # state in the item itself for both old and new positions - the same
  # transition may need to be made for many viewing players, so
  # setting the state as "part of the transition" doesn't work well.
  # Further complicating things, different players aren't guaranteed
  # to be seeing this Displayable object in the same state at the
  # start of the transition, since they could have just arrived and
  # missed an animation, for example.
  #
  # @param player [Pixiurge::Player] The player to show
  # @param old_position [String] The old/beginning position string
  # @param new_position [String] The new/ending position string
  # @return [void]
  # @since 0.1.0
  def move_for_player(player, old_position, new_position)
    raise "This message should not be called!"
    #player.message ["displayMoveStackToPixel", self.spritestack[:name], pixel_x, pixel_y, { "duration" => time_to_walk } ]
  end
end
