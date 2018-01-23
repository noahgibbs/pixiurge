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

  # Messages to display the TMX object.
  #
  # @param player [Pixiurge::Player] The player to show this Displayable to
  # @return [Array] Message to send to player
  # @since 0.1.0
  def messages_to_show_player(player)
    [ { "type" => "tmx", "url" => @entry["filename"] } ]
  end

end
