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
  attr_reader :name        # Name, which should be the same as the Demiurge item name if there is one.

  # Most recently-displayed coordinate and location. This can vary
  # significantly from the Demiurge item's location during a long
  # series of movement notifications - the Demiurge item may already
  # be at the final location, while the notifications go one at a time
  # through the places in between. In general the EngineConnector will
  # assign these coordinates and tell the Displayable to play a
  # movement animation, but the Displayable can't easily know exactly
  # what happens when.
  attr_reader :x              # Most recently drawn coordinates
  attr_reader :y
  attr_reader :location_name  # Most recently drawn Demiurge location name
  attr_reader :location_displayable

  # For a tiled-type area, {#block_width} and {#block_height} are the
  # tile height and width of this Displayable in pixels.  This isn't
  # the tile size of this object's location - it's the tile size of
  # this object itself for any items that might move inside of it or
  # on top of it.
  attr_reader :block_width
  attr_reader :block_height

  # This is the most recently-displayed position of this
  # Displayable. When it changes, fields like {#x} and
  # {#location_name} get updated automatically.
  attr_reader :position

  # Constructor
  #
  # @param name [String] The Demiurge item name for this Displayable
  # @param engine_connector [Pixiurge::EngineConnector] The Pixiurge EngineConnector this Displayable belongs to
  # @since 0.1.0
  def initialize name:, engine_connector:
    @name = name
    @engine_connector = engine_connector

    # Most child classes should override this
    @block_width = 1
    @block_height = 1
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
    @location_displayable = @engine_connector.displayable_by_name(@location_name)
    nil
  end

  # Show this Displayable to a player by sending a
  # DISPLAY_SHOW_DISPLAYABLE message.  Be very careful overriding this
  # method - a Displayable that uses something other than a single
  # DISPLAY_SHOW_DISPLAYABLE may not work properly if put inside a
  # {Pixiurge::Container} or other Displayable that contains other
  # Displayables.
  #
  # @param player [Pixiurge::Player] The player to show this Displayable to
  # @return [void]
  # @since 0.1.0
  def show_to_player(player)
    msgs = messages_to_show_player(player)
    return if msgs.nil? || msgs.empty?
    player.message(Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, @name, *msgs)
  end

  # Return zero or more messages for {#show_to_player}. An empty array
  # of messages mean "don't show" or "no messages are required to
  # show." The primary reason for this having an independent existence
  # is for containers and other Displayables that can contain other
  # Displayables - this is a way "hide" this Displayable inside
  # another one.
  #
  # @param player [Pixiurge::Player] The player to show this Displayable to
  # @return [Array] A JSON-serializable Array of messages which are used to show the Displayable to this player
  # @since 0.1.0
  def messages_to_show_player(player)
    raise "Override #messages_to_show_player when inheriting from Pixiurge::Displayable!"
  end

  # Hide this Displayable from a player. The default method assumes
  # this Displayable uses a SpriteStack and has set the spritesheet
  # and spritestack names already. For other display methods, override
  # this method in a subclass.
  #
  # @param player [Pixiurge::Player] The player to hide this Displayable from
  # @return [void]
  # @since 0.1.0
  def destroy_for_player(player)
    player.message Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_DISPLAYABLE, self.name
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
  def move_for_player(player, old_position, new_position, options = {})
    player.message( Pixiurge::Protocol::Outgoing::DISPLAY_MOVE_DISPLAYABLE, @name, { "old_position" => old_position, "position" => new_position, "options" => options } )
  end
end
