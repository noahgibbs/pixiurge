# An Invisible Displayable is just a visual no-op - showing and hiding
# it do nothing. You could use a single empty spritestack to get the
# same effect. This permits "showing" items that shouldn't have any
# visible presence without doing something too tricky.
#
# @since 0.1.0
class Pixiurge::Display::Invisible < Pixiurge::Displayable
  def show_to_player(player)
  end

  def hide_from_player(player)
  end

  def move_for_player(player, old_pos, new_pos, options)
  end
end
