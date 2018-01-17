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
  # @param demi_item [Demiurge::StateItem] A Demiurge StateItem for this Displayable to indicate
  # @param name [String] The Demiurge item name for this Displayable
  # @param engine_connector [Pixiurge::EngineConnector] The Pixiurge EngineConnector this Displayable belongs to
  # @since 0.1.0
  def initialize particle_parameters, demi_item:, name:, engine_connector:
    @particle_parameters = particle_parameters
    super(demi_item: demi_item, name: name, engine_connector: engine_connector)
  end

  # Show this Displayable to a player.
  #
  # @param player [Pixiurge::Player] The player to show this Displayable to
  # @return [void]
  # @since 0.1.0
  def show_to_player(player)
    player.message(Pixiurge::Protocol::Outgoing::DISPLAY_SHOW_DISPLAYABLE, @name, { "type" => "particle_source", "params" => @particle_parameters } )
    nil
  end

  # See the parent method #{Pixiurge::Displayable#move_for_player} for
  # more general information on this method.
  #
  # A particle source doesn't have to do anything special to move,
  # it just moves.
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
