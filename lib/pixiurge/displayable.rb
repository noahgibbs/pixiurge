# Pixiurge::Display is the parent namespace for various more specific
# Displayable subtypes.
#
# @since 0.1.0
module Pixiurge::Display; end

# A Pixiurge Displayable handles server-side display of in-world
# simulated items. This doesn't directly mess with Javascript or
# Pixi.js code, but it sets up data for display primitives like
# sprites, TMX areas, particles, animations and so on.
#
# The {Pixiurge::Player} knows what objects are being displayed, while
# the {Pixiurge::Displayable}s know how to send messages to display
# themselves.
#
# More complex visual groupings like tilemap areas and humanoid bodies
# inherit from this class.
#
# @see file:CONCEPTS.md
# @since 0.1.0
class Pixiurge::Displayable
  attr_reader :demi_item   # Demiurge item that this displays
  attr_reader :name        # Name, which should be the same as the Demiurge item name if there is one.

  # Most recently-displayed coordinate and location. This can vary
  # significantly from the Demiurge item's location during a long
  # series of movement notifications - the Demiurge item may already
  # be at the final location, while the notifications go one at a
  # time through the places in between.
  attr_reader :x              # Most recently drawn coordinates
  attr_reader :y
  attr_reader :location_name  # Most recently drawn Demiurge location name
  attr_reader :location_displayable

  # For a tiled-type area, these are the tile height and width of this Displayable in pixels
  attr_reader :block_width
  attr_reader :block_height

  # For a tiled-type area, these are the tile height and width of the location (backdrop) of this Displayable in pixels
  attr_reader :location_block_width
  attr_reader :location_block_height

  # This is the most recently-displayed position of this Displayable
  attr_reader :position

  # Constructor
  #
  # @param demi_item [Demiurge::StateItem] A Demiurge StateItem for this Displayable to indicate
  # @param name [String] The Demiurge item name for this Displayable
  # @param engine_connector [Pixiurge::EngineConnector] The Pixiurge EngineConnector this Displayable belongs to
  # @since 0.1.0
  def initialize demi_item:, name:, engine_connector:
    @name = name
    @demi_item = demi_item
    @demi_name = demi_item.name  # Usually the same as @name
    @engine_connector = engine_connector
    raise "Non-matching name and Demiurge name!" if @demi_item && @demi_item.name != name
    @demi_engine = demi_item.engine
    self.position = demi_item.position if demi_item && demi_item.position
  end

  # This method is called when Demiurge is, or may have been,
  # reloaded.  Demiurge item names, handlers and so on stay the same
  # and state is preserved. But StateItems are reinstantiated and must
  # be looked up again. This method updates only this single
  # Displayable, so it must be called on all Displayables, normally by
  # the EngineConnector.
  #
  # @return [void]
  # @since 0.1.0
  def demiurge_reloaded
    @demi_item = @demi_engine.item_by_name(@demi_name)
    @location_item = @demi_engine.item_by_name(@location_name)
    @location_displayable = @engine_connector.displayable_by_name(@location_name)
  end

  # Move this Displayable to a new position. This is normally done by
  # the EngineConnector, along with updating everyone who can perceive
  # this Displayable. Directly setting this in a different way may not
  # update all parties that the item has moved.
  #
  # @param new_position [String] The new Demiurge position
  # @return [void]
  # @since 0.1.0
  def position=(new_position)
    @position = new_position
    @location_name, @x, @y = ::Demiurge::TiledLocation.position_to_loc_coords(new_position)
    @location_item = @demi_engine.item_by_name(@location_name)
    @location_displayable = @engine_connector.displayable_by_name(@location_name)
    if @location_item && @location_item.respond_to?(:tiles)
      @location_block_width = @location_displayable.block_width
      @location_block_height = @location_displayable.block_height
    else
      @location_block_width = nil
      @location_block_height = nil
    end
    nil
  end

  # Show this Displayable to a player, generally by sending messages.
  #
  # @param player [Pixiurge::Player] The player to show this Displayable to
  # @return [void]
  # @since 0.1.0
  def show_to_player(player)
    raise "Override Displayable#show_to_player!"
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
    player.message Pixiurge::Protocol::Outgoing::HIDE_DISPLAYABLE, self.name
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
    raise "Please override this method!"
    #player.message ["displayMoveStackToPixel", self.spritestack[:name], pixel_x, pixel_y, { "duration" => time_to_walk } ]
  end
end
