# A Player object handles the network connection to a single browser,
# via a protocol over Websockets. It also keeps track of what visual
# objects are currently visible in the browser, and handles panning
# (moving the window of visible display around.)
#
# A Player is linked to a Displayable object on creation. The
# EngineConnector normally handles the movement of this object - the
# player just draws and updates what it is told to.
#
# @since 0.1.0
class Pixiurge::Player
  # The Player's name, which should match its Displayable's name and it's Demiurge object's name
  attr_reader :name
  # A websocket object for low-level network I/O
  attr_reader :websocket
  # The Displayable object the player is identified with
  attr_reader :displayable

  # Constructor. Set this player up with the appropriate network
  # settings, Displayable object, engine connector and so on.  This is
  # normally called by the EngineConnector.
  #
  # @param websocket [Websocket] A Websocket object for low-level network I/O
  # @param name [String] The name for the player's account, Demiurge item, Displayable and so on
  # @param displayable [Pixiurge::Displayable] The player's displayable presence
  # @param engine_connector [Pixiurge::EngineConnector] The EngineConnector coordinating this game
  # @param display_settings [Hash] JSON-serializable display settings to send to the browser during initial setup
  # @return [void]
  # @since 0.1.0
  def initialize(websocket:, name:, displayable:, engine_connector:, display_settings: {})
    @websocket = websocket
    @name = name
    @displayable = displayable
    @engine_connector = engine_connector

    @currently_shown = {}

    # The player object expects to have a location and viewport set
    # pretty much immediately after creation, so we don't send a
    # message for it yet. The EngineConnector will cause the Player
    # viewpoint to begin following their Demiurge Agent, pretty much
    # immediately.
    @pan_center_x = 0
    @pan_center_y = 0

    display_init_message(display_settings)
  end

  # Send the message to initialize the display. If you want to send
  # additional settings or customize existing settings like display
  # width and height per player, this is a pretty good place to do
  # that. This is normally called by the Player constructor.
  #
  # @param display_settings [Hash] The display settings to send, if unmodified
  # @return [void]
  # @since 0.1.0
  def display_init_message(display_settings)
    message(Pixiurge::Protocol::Outgoing::DISPLAY_INIT, display_settings)
    nil
  end

  # Send a message to the connected browser for this player. This will
  # serialize to JSON. It respects the record_traffic setting for the
  # Pixiurge app.
  #
  # @param msg_name [String] The protocol message name, normally a constant from {Pixiurge::Protocol}
  # @param args [Array] A JSON-serializable list of arguments to pass with this message
  # @return [void]
  # @since 0.1.0
  def message(msg_name, *args)
    out_str = MultiJson.dump [ msg_name, *args ]
    record_traffic = @engine_connector.app.record_traffic
    File.open(@engine_connector.app.outgoing_traffic_logfile, "a") { |f| f.write out_str + "\n" } if record_traffic
    @websocket.send out_str
    nil
  end

  # Show this Displayable to the player and track that it has been
  # shown. A later {#destroy_displayable} or {#destroy_all_displayables}
  # call will normally be needed eventually to cause the displayable
  # to disappear and be unloaded from the browser - this will usually
  # happen automatically if the player changes locations in such a way
  # as to lose previous visibility.
  #
  # @param displayable [Pixiurge::Displayable] The displayable to show
  # @return [void]
  # @since 0.1.0
  def show_displayable(displayable)
    displayable.show_to_player(self)
    @currently_shown[displayable.name] = displayable
    nil
  end

  # This destroys a given displayable for this player
  #
  # @param disp [Pixiurge::Displayable] The displayable object to destroy, if it's currently shown
  # @return [void]
  # @since 0.1.0
  def destroy_displayable(disp)
    return unless @currently_shown[disp.name]
    disp.destroy_for_player(self)
    @currently_shown.delete(disp.name)
    nil
  end

  # This destroys a given displayable for this player by name
  #
  # @param item_name [String] The name of the item to destroy
  # @return [void]
  # @since 0.1.0
  def destroy_displayable_name(item_name)
    return unless @currently_shown[item_name]
    @currently_shown[item_name].destroy_for_player(self)
    @currently_shown.delete(item_name)
    nil
  end

  # Destroy all displayables, including foregrounds and backdrops.
  #
  # @return [void]
  # @since 0.1.0
  def destroy_all_displayables
    #@currently_shown.each do |item_name, displayable|
    #  displayable.destroy_for_player(self)
    #end
    # Let the front end know: hints, preloads and whatnot... Clear it all.
    self.message Pixiurge::Protocol::Outgoing::DISPLAY_DESTROY_ALL
    @currently_shown = {}
    nil
  end

  # Move the given Displayable from the old to the new position for
  # the given player. Options can be supplied to change the nature of
  # the movement in Displayable-specific ways. For instance, there may
  # be a difference between teleporting, swimming, walking and
  # running, or it may be possible to supply a speed or a duration.
  #
  # @param displayable [Pixiurge::Displayable] The currently-shown Displayable to be moved
  # @param old_position [String] The old position string within the same location
  # @param new_position [String] The new position string within the same location
  # @param options [Hash{String=>String}] JSON-serializable hash of options to pass to the Displayable
  # @return [void]
  # @since 0.1.0
  def move_displayable(displayable, old_position, new_position, options = {})
    return unless @currently_shown[displayable.name]
    return if old_position == new_position

    displayable.move_for_player(self, old_position, new_position, options)
    nil
  end

  # Pan the display to a pixel offset in the current backdrop.
  #
  # @param x [Integer] The new x pixel coordinate for the center of the display
  # @param y [Integer] The new y pixel coordinate for the center of the display
  # @param options [Hash] Options to send to the front end for handling this pan
  # @return [void]
  # @since 0.1.0
  def send_instant_pan_to_pixel_offset(x, y, options = {})
    return if x == @pan_center_x && y == @pan_center_y
    @pan_center_x = x
    @pan_center_y = y
    message Pixiurge::Protocol::Outgoing::DISPLAY_PAN_TO_PIXEL, x, y, options
    nil
  end

  # Pan the display to a coordinate offset in the current backdrop.
  #
  # @param x [Integer] The new x block coordinate for the center of the display
  # @param y [Integer] The new y block coordinate for the center of the display
  # @param options [Hash] Options to send to the front end for handling this pan
  # @return [void]
  # @since 0.1.0
  def pan_to_coordinates(x, y, options = {})
    loc = displayable.location_displayable
    send_instant_pan_to_pixel_offset(x * loc.block_width, y * loc.block_height, options)
    nil
  end
end
