# This is a great place to put the player code, any InertStateItems
# you'll be using and other administrative stuff.

# What does this do? See the extensions folder. This is a simple
# example of a Ruby extension to the World Files that can be useful.
inert "players"

# This zone is different from the special "admin" item name used for
# actions of the world itself. But it's a great place to put your
# player template and to store players "offline" when they're not in
# the world.
#
# It's possible to create and destroy player bodies rather than
# restoring them, of course. But if you want to keep any changes
# (in-body inventory, for instance) then you'll want to keep the body
# somewhere. Here's a way you can do that.
zone "admin zone" do
  agent "player template" do
    # No position or location - this isn't a visible object, it's a
    # template to instantiate.

    # Action that gets performed on character's body being created
    define_action("create") do
      if ["bob", "angelbob", "noah"].include?(item.name)
        item.state["admin"] = true
      end
    end

    # Action that gets performed on login
    define_action("login", "engine_code" => true) do
      raise("Called login on a non-player item!") unless item.state["$player_body"]
      player_name = item.name
      item.state["player"] ||= player_name
      player_item = engine.item_by_name("players")
      player_state = player_item.state[player_name]
      current_position = player_state ? player_state["active_position"] : nil
      player_item.state.delete "active_position" # Delete the old active position
      if current_position
        item.move_to_position(current_position)
      else
        x, y = engine.item_by_name("start location").tmx_object_coords_by_name("start location")
        item.move_to_position "start location##{x},#{y}"
      end
    end

    define_action("logout") do
      player_state["active_position"] = item.position
      # Logged out? Teleport the player's agent to the "adminzone" zone,
      # in a sort of suspended animation.
      move_to_instant("admin zone")
    end

    define_action("move", "tags" => ["player_action"]) do |direction|
      location, next_x, next_y = position_to_location_and_tile_coords(item.position)

      case direction
      when "up"
        next_y -= 1
      when "down"
        next_y += 1
      when "left"
        next_x -= 1
      when "right"
        next_x += 1
      else
        raise "Unrecognized direction #{direction.inspect} in 'move' action!"
      end
      next_position = "#{location}##{next_x},#{next_y}"

      # Just a straight-up move-immediately-if-possible, no frills.
      move_to_instant(next_position)
      player_state["active_position"] = item.position
    end

    define_action("statedump", "tags" => ["admin", "player_action"]) do
      dump_state
    end

    define_action("reboot server", "tags" => ["admin", "player_action"]) do
      dump_state
      # If you run the server with "rerun" or otherwise check for
      # this, you can make the restart happen from outside the app but
      # be triggered by this file.
      FileUtils.touch "tmp/restart.txt"
    end

    display do
      tile_animated_sprite tilesets: [{
          url: "/sprites/female_tilesheet.png",
          tile_width: 80,
          tile_height: 110,
        }],
      animations: {
        stand: { after: [ { name: "stand", chance: 3 }, { name: "idle2" }, { name: "idle3" }, { name: "idle4" }],
          frames: [
            { frame_id: 24, duration: 5000 },
            { frame_id: 1, duration: 1000 },
            { frame_id: 24, duration: 5000 },
            { frame_id: 23, duration: 1000 } ]
        },
        idle2: { after: "stand",
          frames: [
            { frame_id: 24, duration: 5000 },
          ]
        },
        idle3: { after: "stand",
          frames: [
            { frame_id: 24, duration: 2000 },
            { frame_id: 1, duration: 5000 },
            { frame_id: 24, duration: 1000 } ]
        },
        idle4: { after: "stand",
          frames: [
            { frame_id: 24, duration: 1000 },
            { frame_id: 1, duration: 2000 },
            { frame_id: 2, duration: 500 },
            { frame_id: 3, duration: 1500 },
            { frame_id: 4, duration: 1500 },
            { frame_id: 24, duration: 1000 } ]
        },
        walk: { after: "stand", frames: [ { frame_id: 10, duration: 250 }, { frame_id: 11, duration: 250 } ] * 3 },
        jump: { after: "stand", frames: [ { frame_id: 1, duration: 250 }, { frame_id: 2, duration: 250 }, { frame_id: 4, duration: 250 } ] },
      },
      animation: "stand"
    end
  end
end
