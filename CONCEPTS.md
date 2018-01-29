# Pixiurge Concepts

Pixiurge runs a simulation on the server, while putting up a browser
interface in front of it. This can turn a simulation on the server
into a nice playable game in many people's web browsers.

Pixiurge is somewhat inspired by Rails: it tries to be
batteries-included, opinionated and friendly to new users. And while
there's definitely some "Ruby magic" happening, Pixiurge's magic is
well-documented and tries to get out of your way.

Inside, Pixiurge has several major components: the simulation, the
network server and the in-browser front end. Obviously there are many
smaller components inside these and connecting them. But it's useful
for you to think of Pixiurge as a sort of connector between these
major components. It will also be simpler for you to learn Pixiurge
one or two components at a time instead of everything all at once.

Pixiurge runs its simulation and displays the results in the browser
continually. It accepts control information from the browsers and
feeds the resulting player actions into the simulation.

It's easier to build something if you can use existing
pieces. Pixiurge is named after its simulation engine (Demiurge) and
its in-browser display library (PIXI.js). Most of the pieces of
Pixiurge are open-source and open standards of various kinds:
Websockets, Faye, EventMachine and even Ruby itself are great
examples. Pixiurge also intentionally borrows a lot of display
conventions from ManaSource-engine and similar games like The Mana
World, Land of Fire and Source of Tales, as well as OpenGameArt.org
and the Liberated Pixel Cup. It uses those art styles and sprite
sizes.  Pixiurge uses the ManaSource-specific subformat of TMX files
and Tiled editor data. See http://mapeditor.org for more about Tiled.

## Software Architecture

<img src="https://noahgibbs.github.io/pixiurge/images/pixiurge_architecture_2018_01.png"> </img>

It's useful to think of Pixiurge with several major components talking
to each other - there are things that happen entirely in the front
end, such as playing "idle" animations for a player or a fountain of
particles... Which don't necessarily involve the server at all. But
sometimes an event goes from the front end to the back end, crossing
the border between the two components.

The Demiurge engine runs inside a Ruby EventMachine server which uses
Websockets to talk to the connected browsers. This is usually the same
web server that provides assets like maps, Javascript, graphics and
sounds.

The websockets are connected to browsers, which can send control
information *to* the server and receive simulation and feedback
information *from* the server. Pixiurge uses a simple
JSON-over-websocket protocol to communicate back and forth between
browsers and the server.

A Demiurge engine knows how in-world objects act -- it knows how often
a particular Agent moves, or what it says. Demiurge does *not* know
how they look, such as whether a particular pictures goes with a
particular agent or room. Pixiurge is the adapter to make the Demiurge
world visible on a screen.

If we drill down a bit more, what are the major parts of a Pixiurge
server?

* The Demiurge engine, which runs on the server; this calculates the in-game world
* The EngineConnector, which watches the Demiurge simulation and notifies Pixiurge about what happens inside
* Displayables, which keep track of how Demiurge objects get shown to human players
* Player objects, which keep track of what Displayables have been seen and know the JSON protocol
* Browser-side Javascript code, to get human input and show everything to the human player

## World Simulation with Demiurge

Demiurge is a world simulation, and Pixiurge mostly stays out of the
internals. A Demiurge engine should mostly run the same whether it's
hooked up to a display library or not... Except for players and their
actions. Pixiurge translates a player's in-browser behavior to
Demiurge simulated actions.

A player is represented by a Demiurge item called an Agent. The human
player's browser input turns into Agent actions.

Certain administrative actions may turn into more exotic
occurrences. And administrator may create new Demiurge items or
perform non-Agent actions - a statedump or server reboot won't
normally be an Agent action, but it could happen in response to an
administrator hitting a button.

But in general, a player's UI actions will turn into queued actions in
Demiurge. But first they'll be sent as Websocket messages by the
browser and decoded in the Pixiurge server, to be given to the
Demiurge simulator.

### The Cycle of Simulation

When a player takes action (moves, fights, speaks or whatever) the
browser doesn't normally display the result immediately. Instead, that
action is sent to the server, which determines what happens to
it. Demiurge picks it up on the next "tick" of the simulation and
sends out the results of the action.

Would it make more sense to just show the player's actions
immediately? Often not. If a player moves left, they could be blocked
by a wall. A trap could trigger. There might be slippery ground that
makes them move farther than they thought. By having the engine accept
the action and send the results, the user's browser doesn't have to
know about all these things. It can send the action and wait for an
answer.

The down-side of all this is that it limits the speed of
feedback. Very little that the player does can happen faster than once
per tick. You'd never want to build a rhythm game or a fast-paced
platformer this way. Pixiurge is designed to have the player make
choices and wait for the results. It's meant for a slower-paced game,
more like Stardew Valley or Dwarf Fortress, where the user's exact,
instant actions aren't make-or-break.

## Pixiurge Conventions

Demiurge leaves many things to the user's preferences. It tries to be
very flexible and not restrict very much. That's as it should
be. Pixiurge takes a Rails-like opinionated approach and locks down a
lot of how Demiurge gets configured. That's also as it should be.

Here are some example conventions Pixiurge expects and/or enforces:

* A Player's account name is the same as their Demiurge body item
  name, which is the same as the Displayable name.

* In general, Demiurge item names match the names of their
  corresponding Pixiurge Displayable objects. A Demiurge item won't
  necessarily have a Displayable, but it will never have more than
  one.

* Most Demiurge items are in a Location, which is in a Zone. The
  exceptions to this are the Locations and Zones themselves, Inert
  State Items for tracking variables, and Agents that are currently
  inactive, which are in Zones. Zones are top-level objects - they
  aren't inside anything. If you query a Zone's location, the returned
  object is that same Zone.

* The player will have a Demiurge item instantiated for them by your
  code, and various Demiurge action names will be needed for their
  Demiurge item - "create", "login" and so on - if you want to
  customize what happens at those times. Pixiurge will use the
  reserved state variable name "$player_body" to indicate that this is
  a special item.

* TMX files should use only embedded tilesets, not external TSX files.
  Maps should be orthographic with right-down renderorder, and not use
  any options (like layer offsets) that can't be set in the Tiled
  UI. All layers should have the same dimensions. No infinite or
  procedural TMX maps are supported.

Pixiurge also assumes that a lot of your customization of the game
world will be done in the Demiurge World Files. For instance, it's
normal to handle on-login and on-creation actions with Demiurge
actions in the World Files.

## Displaying the World: Connecting Simulation and the Front End

A lot of Pixiurge is an intermediate level of message handling,
passing notes back and forth. A user hits a key and instructs their
Agent to move inside the Demiurge simulation. Another user says "hi,
everybody!" and Demiurge notifies the three players in the same
room. A new user sends their password and logs in, which means more
messages as they appear in the room.

The EngineConnector and the Pixiurge App are the two primary pieces of
code passing these messages around - the EngineConnector monitors the
Demiurge engine, while the Pixiurge App handles Websocket connections
to web browsers. There are other software components such as
Displayables. Most of Pixiurge is about passing the messages back and
forth in a reasonable way.

### Displayables on the Server, sprites on the Client

A Pixiurge server provides different views into Demiurge for a lot of
different clients at a lot of different times. The same zone or room
looks different to different players, as you'd expect it to, and of
course each player only sees a sliver of the game world at any time.

There is one single Demiurge engine on the server, with one copy of
each unique item. When a Demiurge item changes, several different
players may be able to see it, and may receive updates to show the
change in their browser. They may also see the change in different
ways: can player A see it at all? Can player B see the enchanted
invisible item? Does player C get a different description of the item
because his lore skills are higher or lower?

Pixiurge keeps a single server-side Displayable for each potentially
visible Demiurge object (and for some that will never be visible.)
When each Displayable changes, it may send updates to a bunch of
players who can see it. So: each Demiurge item has a matching
server-side Pixiurge Displayable.

When the Demiurge item changes, it sends a Demiurge notification. The
single, server-side EngineConnector object subscribes to all Demiurge
notifications and provides all the players with a constant, consistent
view of what's happening by translating the notifications into
Pixiurge messages over Websockets. The browsers, when they get the
messages, will show the human players what changed.

A particular browser will have items representing some of the
Displayables in Pixiurge. These in-browser objects include
"spritestacks", which may have multiple layers of sprites in their
Pixi.js representation. For instance, a ManaSource-style humanoid like
a player or enemy will normally be several layers of "grids", where
each grid is (usually) 1 sprite by 1 sprite, and each sprite is
64x64. The multiple layers, if present, are for things like hair,
clothing and equipment which are modeled as overlaid layers.

### Three Layers of Snapshots: Demiurge, Displayables, the Browser

Notifications can cause some complications - more than one thing can
happen to an item during a single tick, for instance. And
notifications go out in a big batch after the tick is over, not
immediately as things happen. So when Pixiurge is processing a
notification, the item's condition may have changed in the mean
time. The player is seeing the old pre-notification state. The
notification tells what happened. But the item may have changed again
in a later notification, so we can't assume we're just updating it to
the Demiurge latest. This makes things a little complicated for
EngineConnector. It can't just get the latest state from Demiurge, because
that may not be the state it wants or shows.

We also can't assume every player sees the Displayable the same way,
even if they're up to date. If Bob and Jane are standing in two
different parts of the same room, Bob may be able to see different
items than Jane, and they're scrolled to different positions. If Jane
has a better "perception" in some way than Bob, she may even see
things that, in effect, don't exist at all for Bob, and which may not
get sent to his browser.

### Displayables and Players

A Pixiurge "Player" object is a server object that coordinates what
gets sent to a particular browser. It will correspond to a Demiurge
Agent, though it's possible to make that Agent invisible and/or unable
to act if you want to.

The Player object answers important questions like "is this browser
already showing this area?" and "can this player currently see this
action that's happening?" As a side effect, the Player object
coordinates any "fog of war" you need to have - making sure that the
browser doesn't receive information it shouldn't. You can't ever truly
trust browser code, so any cheat-proofing *must* happen on the
server. The Player object is the final place to do that.

When a Displayable changes (e.g. is created or destroyed or moved)
then the various Player objects need to know and send messages to the
browser so that those actions can be shown to the human viewers.

Several objects are involved in notifying about changes. The
EngineConnector subscribes to the notification from Demiurge and makes
appropriate calls to the Displayables to let them know they've
changed. The Displayables and the Player both know a bit about how to
show particular things visually with Websocket messages.

The Player object keeps track of whether a specific browser has seen a
Displayable, and where. It shows and hides them. It can start and stop
animations. It keeps track of Panning - what area the player is
looking at, and making sure that the player's view continues to follow
along and see the right things in an area larger than their browser
window.

In a software sense, a Displayable subclass knows how to display or
hide itself using messages over Websockets. A Player knows what
objects are currently displayed, but must ask a Displayable to display
itself to get the specific messages.

## The Front End

Pixiurge includes a display library with some built-in display
primitives. It knows how to display a JSON TMX tiled area, for
instance, and to show hovering text, and humanoid figures with
equipment.

### Pixiurge Websocket Protocol

The Pixiurge Websocket Protocol is simple and designed for easy
testing and reading by humans. That's bad if you need high
performance, but good if you want to put together games easily.

## Pixiurge Performance Limits

It's easy to read all this stuff about "no twitch games", "designed
for simulation" and so on and think, "yeah, but that's just because
he's not good at optimizing." Fair enough. But let's talk about some
of the fundamental limits on Pixiurge and what's going on with that.

### Javascript and Ruby

Neither Javascript nor Ruby is all that fast. Both are garbage
collected, so it's _really_ hard to avoid random slowdowns, at least
occasionally.

You can fix the Javascript side of that with a plugin such as Unity,
or using something like NaCl for Chrome. Or by building out an actual
native app, obviously. I wouldn't normally recommend starting from
Pixiurge, or a web browser, or Websockets if that's your approach. If
you're going to build from scratch, that's cool. Do that.

The Ruby side can be handled with C extensions to Ruby if you want to
(hint: you do not.) But mostly the server is going to be slow because
it's a network server and you have to wait for packets, not because
it's Ruby. Things have to get pretty bad before Ruby is truly your
bottleneck unless you're doing a lot of in-Ruby calculation.

If you're doing a lot of in-Ruby calculation, I have two
recommendations: Ruby is a great prototyping language, but you're
going to want to rebuild in order to scale out game simulation - Ruby
is *not* going to build you the equivalent of Crysis, though it might
build the equivalent of the WoW game servers.

So why build in Ruby? For the same reason you build in
Rails. Server-side processor time is cheap. If you can trade cheap
computer time for expensive human time, do that. Not just to save
money, but to build your initial game quickly and get players.

Why build in Javascript? Because web browsers are everywhere and
that's going to stay true. Because by *far* the widest audience is
browser apps, and that's going to be true for a long time. Because I
don't much care about building AAA-style high-performance "whoah, the
graphics" games, but I care a *lot* about reaching people and talking
to them. I hope you do too.

### Network Round Trips

One of the biggest limits on Pixiurge performance is this: for most
actions, you need a network round trip to the server. Worse, you need
a *Websocket* round trip to the server, which means TCP/IP and
significant per-message overhead.

Can't we fix that?

Well, maybe. It's possible for you to write client-side Javascript
that does things without waiting for the server. But then you're
giving up the convenience of one nice server-side simulation. You
could write a peer-to-peer simulated Javascript library that keeps
everything synchronized,
but... [Do you know how that gets done](https://gafferongames.com/post/state_synchronization/)?

It's totally possible. But if you read a bit, you'll discover that
using TCP means long delays - you have to wait for packets to arrive
in-order. There is no Websocket-style UDP protocol without using
WebRTC, which is massively complicated and not very well supported in
browsers. Worse, it requires anybody setting it up to run
[STUN](https://en.wikipedia.org/wiki/STUN) and
[TURN](https://en.wikipedia.org/wiki/Traversal_Using_Relays_around_NAT)
servers, which are *not* trivial to set up.

There are ways around all of this... *If* you make every player
install a browser plugin, which is how engines like Unity handle
it. It would be wonderful if there were
[some kind of sane in-browser UDP-style protocol](https://en.wikipedia.org/wiki/Netcode)
to handle this. But currently there's no such standard on the
horizon. You have to install a plugin.

If you just want a Javascript twitch game without synchronizing a
bunch of players... Great! Write it in Javascript and send back
occasional data to the server about how the player is doing. Cheating
can be an issue there, but I don't care if you don't. Have fun!

But unfortunately, if you want it to be server-simulated and
multiplayer, your choices are "slow" and "very complicated." Pixiurge
can be one or the other, and I picked "slow" on purpose. I feel like
we already have a lot of great game engines that are complicated and
difficult but powerful and fast - Unity and Unreal are both free to
use until you have revenue and powerful enough to regularly ship AAA
games. I _can't_ compete with that, but I also don't _want_ to compete
with that - they're already great, why would I bother? If you're up
for spending weeks building beautiful 3D art assets, your game engine
code is amazing, and is already written and basically free.

Instead, I'm an old MUD guy. And I miss games that feel like a
neighborhood hang-out, where there are two or three people running it
and they know the regulars. I love little
[Ludum-Dare-style](https://ldjam.com/) games and
[art games](http://ludomancy.com/today/index.html) and
[games that are too meta for their own good](http://store.steampowered.com/app/221910/The_Stanley_Parable/). For
those, I don't think we need Unity or Unreal. Sometimes the tools to
code easily and put a view window on top of it in a browser are
exactly what you need. Sometimes you want a focus on "what can I build
quickly and people may think is kind of cool?" So I built that
instead.
