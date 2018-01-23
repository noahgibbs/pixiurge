module Pixiurge::Display
  # The DisplayBuilder class handles the Display DSL in Demiurge
  # Display blocks for Pixiurge.  It will pull the "display" block
  # from a Demiurge item to create a Pixiurge Displayable for it.
  #
  # @example
  #   builder = Pixiurge::Display::DisplayBuilder.new(item, engine_connector: connector)
  #   displayables = builder.built_objects
  #
  # @since 0.1.0
  class DisplayBuilder
    # The objects built by this DisplayBuilder object
    attr_reader :built_objects
    # The Demiurge item for which a Displayable is being built
    attr_reader :item
    # The EngineConnector in which all this exists
    attr_reader :engine_connector
    # The item name of the Demiurge item (and thus Displayable) being built
    attr_reader :name

    # Constructor. This takes a Demiurge item, which supplies the
    # Displayable's name unless a different name is supplied by
    # keyword.
    #
    # @param item [Demiurge::StateItem] The Demiurge item corresponding to the Displayable
    # @param name [String] This Displayable's name, which must either be the same as the name of the Demiurge item or correspond to no other Demiurge item
    # @param engine_connector [Pixiurge::EngineConnector] The EngineConnector containing this Displayable
    # @since 0.1.0
    def initialize(item, name: item.name, engine_connector:)
      # Several things, such as @item, @name and @engine_connector are intentionally available from the DSL
      @item = item
      @name = item.name
      @engine_connector = engine_connector

      # Built_objects is a readable attribute to get the final result out
      @built_objects = []

      disp = item.get_action("$display")["block"]
      raise("No display action available for DisplayBuilder!") unless disp
      self.instance_eval(&disp) # Create the built objects from the block
    end

    private
    # This adds a built object to the internal array. The parent class
    # doesn't do anything fancy with this, but child classes may (see
    # {Pixiurge::Display::ContainerBuilder}).
    #
    # @param obj [Pixiurge::Displayable] The Displayable object that has been built
    # @return [void]
    # @since 0.1.0
    def add_built_object(obj)
      @built_objects << obj
      nil
    end
    public

    # Create a Displayable container holding one or more other
    # Displayables.
    #
    # @yield An additional Displayable DSL block which creates one or more additional Displayables
    # @return [void]
    # @since 0.1.0
    def container(&block)
      builder = ::Pixiurge::Display::ContainerBuilder.new(item, engine_connector: @engine_connector)
      raise("Display container must supply a block!") unless block_given?
      builder.instance_eval(&block)
      raise("Display container must contain at least one item!") if builder.built_objects.empty?
      add_built_object ::Pixurge::Display::Container.new(builder.built_objects, name: @name, engine_connector: @engine_connector)
    end

    # Create a Displayable particle source according to the passed
    # particle parameters.
    #
    # @param params [Hash] A hash of particle parameters
    # @return [void]
    # @since 0.1.0
    def particle_source(params)
      add_built_object ::Pixiurge::Display::ParticleSource.new(params, name: @name, engine_connector: @engine_connector)
    end

    # Create an invisible Displayable - not only does it not show up
    # on the screen, but it sends no messages to the players.  If you
    # want no Displayable for something, this is the closest
    # equivalent.
    #
    # @return [void]
    # @since 0.1.0
    def invisible
      add_built_object ::Pixiurge::Display::Invisible.new(name: @name, engine_connector: @engine_connector)
    end

    # Create a {Pixiurge::TileAnimatedSprite} as the given
    # Displayable. These sprites show animations from tilesheets, and
    # can transition continuously between multiple animations for
    # things like standing-and-idle animations.
    #
    # For details of the parameters, see
    # {Pixiurge::TileAnimatedSprite}.
    #
    # @param params [Hash] Parameters for the TileAnimatedSprite
    # @return [void]
    # @since 0.1.0
    def tile_animated_sprite(params)
      add_built_object ::Pixiurge::Display::TileAnimatedSprite.new(params, name: @name, engine_connector: @engine_connector)
    end

    # Create a TMX tilemap as the given Displayable. The given TMX
    # filename will be quietly converted to JSON behind the scenes and
    # sent with a separate AJAX loader request.
    #
    # @param filename [String] The server-side relative filename for the TMX file
    # @return [void]
    # @since 0.1.0
    def tmx_map(filename, options = {})
      cache_entry = Demiurge::Tmx::TmxLocation.default_cache.cache_entry("manasource", filename)
      add_built_object ::Pixiurge::Display::TmxMap.new(cache_entry, name: @name, engine_connector: @engine_connector)
    end
  end

  class ContainerBuilder < DisplayBuilder
    # Constructor. This takes a Demiurge item, which supplies the
    # Displayable's name unless a different name is supplied by
    # keyword.
    #
    # @param item [Demiurge::StateItem] The Demiurge item corresponding to the Displayable
    # @param name [String] This Displayable's name, which must either be the same as the name of the Demiurge item or correspond to no other Demiurge item
    # @param engine_connector [Pixiurge::EngineConnector] The EngineConnector containing this Displayable
    # @since 0.1.0
    def initialize(item, name:, engine_connector:)
      # We pass a nil item to this, which means that's what the DSL
      # will see. We'll be incrementing the name for each successive
      # Displayable, which is how we'll keep from having two with the
      # same name.
      super(item, name: name, engine_connector: engine_connector)

      @original_name = name
      @count = 1
      @name = "#{@original_name}@#{@count}"
    end

    private
    # We need to increment the name for each so that each Displayable gets a unique name.
    def add_built_object object
      super
      @count += 1
      @name = "%s@%03d" % [@original_name, @count]
    end
  end
end
