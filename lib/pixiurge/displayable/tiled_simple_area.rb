require "pixiurge/displayable"

class Pixiurge::Display::TiledSimpleArea < ::Pixiurge::Displayable
  attr_reader :spritesheet
  attr_reader :spritestack

  # Display a Pixiurge TMX location as a straightforward spritesheet and spritestack.
  def initialize(demi_item:, name:, engine_connector:)
    super
    tiles = @demi_item.tiles
    @spritesheet = tiles[:spritesheet]
    @spritestack = tiles[:spritestack]
  end

  # Show this Displayable to a player. The default method assumes this
  # Displayable uses a SpriteStack and has set the spritesheet and
  # spritestack names already. For other display methods, override
  # this method in a subclass.
  #
  # @param player [Pixiurge::Player] The player to show this Displayable to
  # @return [void]
  # @since 0.1.0
  def show_to_player(player)
    player.show_sprites_at_position(@demi_item.name, self.spritesheet, self.spritestack, @position)
    nil
  end

  # Hide this Displayable from a player. The default method assumes
  # this Displayable uses a SpriteStack and has set the spritesheet
  # and spritestack names already. For other display methods, override
  # this method in a subclass.
  #
  # @param player [Pixiurge::Player] The player to hide this Displayable from
  # @return [void]
  # @since 0.1.0
  def hide_from_player(player)
    player.hide_sprites(@demi_item.name)
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
