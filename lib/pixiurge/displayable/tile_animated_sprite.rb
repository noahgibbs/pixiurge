# TileAnimatedSprites are good for playing tile-based animations from
# one or more tile sheeets.
#
# @since 0.1.0
class Pixiurge::Display::TileAnimatedSprite < Pixiurge::Displayable
  # Constructor - create the sprite
  #
  # In addition to normal Pixiurge Displayable parameters, a
  # TileAnimatedSprite takes a params hash in a very specific format.
  #
  # @example
  #   ``` javascript
  #   {
  #     tilesets: [
  #       {
  #         name: "name1",
  #         url: "https://first_url.com/path",
  #         tile_width: 32,
  #         tile_height: 32,
  #       },
  #       {
  #         name: "name2",
  #         url: "https://second_url.com/path",
  #         tile_width: 32,
  #         tile_height: 32,
  #         first_frame_id: 37,   # Frame ID of the first tile in this tileset
  #         spacing: 3, # Optional field, default 0
  #         margin: 2,  # Optional field, default 0
  #         reg_x: 16,  # Optional field for anchor/registration x coord, default 0
  #         reg_y: 16,  # Optional field for anchor/registration y coord, default 0
  #       }
  #     ],
  #     animations: {
  #       funny_walk: { frames: [ 1, 2, 3, 4, 5 ], after: "loop" },
  #       second_anim: { frames: [ 7, 2, 4, 1, 6 ] },
  #       third_anim: { frames: [
  #         { tileset: "name1", x: 0, y: 0, width: 32, height: 32, duration: 100 },
  #         { frame_id: 7, duration: 150 },
  #         { tileset: "name2", x: 32, y: 96, width: 32, height: 32, duration: 50 },
  #         7,
  #         15
  #       ], after: "loop" }
  #     }
  #     animation: "funny_walk"
  #   }
  #   ```
  #
  # For tilesets, the url property is where to load the tileset from,
  # usually on the game's asset server(s). The tile_width,
  # tile_height, spacing and margin define the size and location of
  # the frames within a tileset. The first_frame_id defaults to 1 for
  # the first tileset and gives the frame ID (number) for the very
  # first frame number of that tileset. For later tilesets, the frame
  # numbering begins with the next unused frame ID - so a tileset with
  # room for 24 images followed by a tileset with room for 6 images
  # will have frame IDs between 1 and 30 unless one of them sets
  # first_frame_id.
  #
  # Properties for animations: frames, after (opt). Frames is an array.
  # each element may be an integer, in which case it's a frame ID
  #
  # The default value for "after" is "stop". Special values for
  # "after" are "loop" and "stop". It can also be set to the name of
  # another animation in the same TileAnimatedSprite.
  #
  # The "tileset" property of an animation gives the default tileset
  # for any frame that doesn't specify. The default value is the first
  # tileset.
  #
  # The "frames" property of an animation is an array of frame
  # specifications. A frame can be a number, which is a frame number
  # as defined by the tilesets. A frame can also be a structure with a
  # duration and frame_id. Or it can be a structure with a duration,
  # an x and y coordinate for the upper left corner, a width and
  # height, and a tileset name.
  #
  #
  # @param parameters [Hash] A JSON-serializable hash of  options to pass to the front end
  # @param demi_item [Demiurge::StateItem] A Demiurge StateItem for this Displayable to indicate
  # @param name [String] The Demiurge item name for this Displayable
  # @param engine_connector [Pixiurge::EngineConnector] The Pixiurge EngineConnector this Displayable belongs to
  # @since 0.1.0
  def initialize parameters, demi_item:, name:, engine_connector:
    @parameters = parameters
    super(demi_item: demi_item, name: name, engine_connector: engine_connector)
  end

  # Show this Displayable to a player.
  #
  # @param player [Pixiurge::Player] The player to show this Displayable to
  # @return [void]
  # @since 0.1.0
  def show_to_player(player)
    player.message(Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, @name, { "type" => "tile_animated_sprite", "params" => @parameters } )
    nil
  end

  # See the parent method #{Pixiurge::Displayable#move_for_player} for
  # more general information on this method.
  #
  # This displayable doesn't have to do anything special to move, it
  # just moves.
  #
  # @param player [Pixiurge::Player] The player to show
  # @param old_position [String] The old/beginning position string
  # @param new_position [String] The new/ending position string
  # @return [void]
  # @since 0.1.0
  def move_for_player(player, old_position, new_position, options)
    player.message( Pixiurge::Protocol::Outgoing::DISPLAY_MOVE_DISPLAYABLE, @name, { "old_position" => old_position, "position" => new_position, "options" => options } )
  end
end
