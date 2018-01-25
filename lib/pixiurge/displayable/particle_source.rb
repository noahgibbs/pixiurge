# The server does none of the heavy lifting for configuring a Pixiurge
# particle source, but can still pass through enough parameters to
# make one happen. Early on we just pass the parameters through to the
# Javascript, but over time we can do more interesting verification on
# the server to make sure the particle source is basically reasonable
# and correct.
#
# @since 0.1.0
class Pixiurge::Display::ParticleSource < Pixiurge::Displayable
  # Constructor - create the particle source
  #
  # @param particle_parameters [Hash] A JSON-serializable hash of particle source options to pass to the front end
  # @param name [String] The Demiurge item name for this Displayable
  # @param engine_connector [Pixiurge::EngineConnector] The Pixiurge EngineConnector this Displayable belongs to
  # @since 0.1.0
  def initialize particle_parameters, name:, engine_connector:
    @particle_parameters = particle_parameters
    @displayable_type = "particle_source"
    super(name: name, engine_connector: engine_connector)
  end

  # Show this Displayable to a player.
  #
  # @param player [Pixiurge::Player] The player to show this Displayable to
  # @return [Array] Message(s) to show this object to the player
  # @since 0.1.0
  def messages_to_show_player(player)
    messages = super
    messages[0].merge!({ "params" => @particle_parameters })
    messages
  end
end
