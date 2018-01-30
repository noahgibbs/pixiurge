# Sometimes it's useful to just have a container with one or more
# other Displayables inside.  This allows both multiple Displayables
# without a custom type (e.g. a humanoid with a particle source
# attached) or to have multiple pieces with multiple transforms or
# animations (e.g. a shadow as a separate sprite that doesn't move up
# and down when the body jumps.)
#
# @since 0.1.0
class Pixiurge::Display::Container < Pixiurge::Displayable
  attr_reader :contents

  # Constructor - create the container
  #
  # @param displayables [Array<Pixiurge::Displayable>] An array of Displayable items as contents
  # @param name [String] The Demiurge item name for this Displayable
  # @param engine_connector [Pixiurge::EngineConnector] The Pixiurge EngineConnector this Displayable belongs to
  # @since 0.1.0
  def initialize displayables, name:, engine_connector:
    @contents = displayables
    @displayable_type = "container"
    super(name: name, engine_connector: engine_connector)
  end

  # Messages to show this Displayable to a player.
  #
  # @param player [Pixiurge::Player] The player to show this Displayable to
  # @return [Array] Messages to show this container to the player
  # @since 0.1.0
  def messages_to_show_player(player)
    show_contents_msgs = @contents.map do |d|
      msgs = d.messages_to_show_player(player)
      msgs[0].merge!(name: d.name)
      msgs
    end

    messages = super
    messages[0].merge!({ "contents" => show_contents_msgs })
    messages
  end
end
