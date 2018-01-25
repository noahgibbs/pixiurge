# An Invisible Displayable is just a visual no-op - showing and hiding
# it do nothing. You could use a single empty spritestack to get the
# same effect. This permits "showing" items that shouldn't have any
# visible presence without doing something too tricky.
#
# @since 0.1.0
class Pixiurge::Display::Invisible < Pixiurge::Displayable
  # Constructor
  #
  # @param name [String] The Demiurge item name for this Displayable
  # @param engine_connector [Pixiurge::EngineConnector] The Pixiurge EngineConnector this Displayable belongs to
  # @since 0.1.0
  def initialize name:, engine_connector:
    super
    @displayable_type = "invisible"  # This should never go over the network, though...
  end

  # Do nothing to display an Invisible object, don't call super
  #
  # @since 0.1.0
  def messages_to_show_player(player)
    []
  end

  # Do nothing to hide an Invisible object
  #
  # @since 0.1.0
  def destroy_for_player(player)
  end

  # Do nothing to move an Invisible object
  #
  # @since 0.1.0
  def move_for_player(player, old_pos, new_pos, options)
  end
end
