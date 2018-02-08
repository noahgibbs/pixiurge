# This is for a text "effect" - that is, text that exists for a short
# time and then disappears, a bit like a particle.
#
# @since 0.1.0
class Pixiurge::Display::TextEffect < Pixiurge::Displayable
  # Constructor - create the text effect object
  #
  # @param text [String] The text to display
  # @param style [Hash] Text-style properties for how to display it; see "http://pixijs.download/dev/docs/PIXI.TextStyle.html".
  # @param name [String] The Demiurge item name for this Displayable, or the empty string for no given name; unnamed Displayables can only be manually cleared by DestroyAllDisplayables
  # @param duration [Integer] The duration to display the text, in milliseconds; default: 5000
  # @param final_properties [Hash] Final property values after tweening; by default the text will rise (-y coord) and fade (0.1 alpha)
  # @param engine_connector [Pixiurge::EngineConnector] The Pixiurge EngineConnector this Displayable belongs to
  # @since 0.1.0
  def initialize text,
    style: { fill: "yellow", fontSize: "20pt", wordwrap: false, wordWrapWidth: 100 },
    final_properties: { y: "-20", alpha: 0.1 },
    duration: 5000,
    name:, engine_connector:
    @text = text
    @style = style
    @final_properties = final_properties
    @duration = duration
    @displayable_type = "text_effect"
    super(name: name, engine_connector: engine_connector)
  end

  # Messages to show this Displayable to a player.
  #
  # @param player [Pixiurge::Player] The player to show this Displayable to
  # @return [Array] Messages to show this container to the player
  # @since 0.1.0
  def messages_to_show_player(player)
    messages = super
    messages[0].merge!({ "text" => @text, "style" => @style, "duration" => 5000, "finalProperties" => @final_properties })
    messages
  end
end
