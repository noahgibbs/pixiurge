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

    def initialize(item, engine_connector:)
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

    def manasource_humanoid(&block)
      builder = HumanoidBuilder.new(@item, engine_connector: @engine_connector)
      builder.instance_eval(&block) if block_given?
      @built_objects << builder.built_obj
    end

    def particle_source(params)
      @built_objects << ::Pixiurge::Display::ParticleSource.new(params, name: @item.name, demi_item: @item, engine_connector: @engine_connector)
    end

    def invisible
      @built_objects << ::Pixiurge::Display::Invisible.new(name: @item.name, demi_item: @item, engine_connector: @engine_connector)
    end
  end

  class HumanoidBuilder
    def initialize(agent, engine_connector:)
      @agent = agent  # Demiurge Agent item
      @engine_connector = engine_connector
      @layers = [ "male", "robe_male" ] # Default appearance, if not given
    end

    def layers(*layer_names)
      @layers = (layer_names).flatten
    end

    def built_obj
      ::Pixiurge::Display::Humanoid.new @layers, name: @agent.name, demi_item: @agent, engine_connector: @engine_connector
    end
  end
end
