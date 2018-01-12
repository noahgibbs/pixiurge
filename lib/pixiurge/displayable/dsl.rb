# This Builder class handles the Display DSL in Demiurge Display blocks for Pixiurge.
#
# @since 0.1.0
module Pixiurge::Display
  class DisplayBuilder
    attr_reader :built_objects

    def self.build_displayable(block)
      builder = DisplayBuilder.new
      builder.instance_eval(&block)
    end

    def initialize(item, engine_connector:)
      @item = item
      @built_objects = []
      @engine_connector = engine_connector
      disp = item.get_action("$display")["block"]
      raise("No display action available for DisplayBuilder!") unless disp
      self.instance_eval(&disp) # Create the built objects from the block
    end

    def manasource_humanoid(&block)
      builder = HumanoidBuilder.new(@item, engine_connector: @engine_connector)
      builder.instance_eval(&block)
      @built_objects << builder.built_obj
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
