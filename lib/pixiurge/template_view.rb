module Pixiurge
  class TemplateView
    # HTML to include JavaScript for the appropriate Pixiurge scripts.
    def pixiurge_scripts
      <<-SCRIPTS
        <script src="/pixiurge/pixiurge.js"></script>
        <script src="/pixiurge/pixiurge_websocket.js"></script>
        <script src="/pixiurge/pixiurge_display.js"></script>
        <script src="/pixiurge/pixiurge_displayable.js"></script>
        <script src="/pixiurge/pixiurge_utils.js"></script>
        <script src="/pixiurge/pixiurge_tile_utils.js"></script>
        <script src="/pixiurge/pixiurge_tile_animated_sprite.js"></script>
        <script src="/pixiurge/pixiurge_tmx_map.js"></script>
        <script src="/pixiurge/pixiurge_displayable_container.js"></script>
        <script src="/pixiurge/pixiurge_loader.js"></script>
        <script src="/pixiurge/pixiurge_input.js"></script>
        <script src="/vendor/jquery-3.2.1.js"></script>
        <script src="/vendor/bcrypt.js"></script>
        <script src="/vendor/pixi-4.6.2.js"></script>
        <script src="/vendor/sha1.js"></script>
      SCRIPTS
    end
  end
end
