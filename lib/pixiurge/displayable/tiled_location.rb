require "pixiurge/displayable"

class Pixiurge::Display::TiledLocation < ::Pixiurge::Displayable
  attr_reader :spritesheet
  attr_reader :spritestack

  # Display a Pixiurge TMX location as a straightforward spritesheet and spritestack.
  def initialize(demi_item:, name:, engine_sync:)
    super
    tiles = @demi_item.tiles
    @spritesheet = tiles[:spritesheet]
    @spritestack = tiles[:spritestack]
  end
end
