require "pixiurge/version"

require "faye/websocket"

# Pixiurge adds display libraries for an HTML game on top of the
# Demiurge engine for game state. Its technical stack includes PixiJS
# as well as Websocket, EventMachine and more.
#
# A Pixiurge game consists of an {Pixiurge::App} connected to an
# Engine. The App handles browser and Websocket connection
# details. The Engine handles the simulation of the game world. See
# {Pixiurge::AppInterface} for details of the App, and
# {Pixiurge::Engine} for the Engine.
#
# The App handles on-the-wire network protocol. See
# {Pixiurge::Protocol} for more details.
#
# The Engine uses the Demiurge library for its underlying
# implementation, but connects Demiurge items to both App events and
# {Pixiurge::Display} objects.
#
# @see file:CONCEPTS.md
# @see Pixiurge::AppInterface
# @see Pixiurge::Engine
# @see Pixiurge::Protocol
# @see Pixiurge::Display
# @since 0.1.0
module Pixiurge;end

require "pixiurge/config_ru"
require "pixiurge/app"
require "pixiurge/authentication"
