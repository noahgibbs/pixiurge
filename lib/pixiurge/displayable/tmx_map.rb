require "pixiurge/displayable"

# A TmxMap uses a Demiurge item's TMX entry as its source of data and
# behavior.
#
# @since 0.1.0
class Pixiurge::Display::TmxMap < ::Pixiurge::Displayable
  # Constructor. Assume we read the TMX cache information from the Demiurge item and display it.
  #
  # @since 0.1.0
  def initialize(tile_cache_entry, name:, engine_connector:)
    super(name: name, engine_connector: engine_connector)
    @entry = tile_cache_entry
    @block_width = @entry["tilewidth"]
    @block_height = @entry["tileheight"]
  end

  # Send messages to display the TMX object.
  #
  # @param player [Pixiurge::Player] The player to show this Displayable to
  # @return [void]
  # @since 0.1.0
  def show_to_player(player)
    player.message Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, @name,
      { "type" => "tmx", "url" => File.join(@entry["dir"], @entry["tmx_name"] + ".json") }
    nil
  end

end
