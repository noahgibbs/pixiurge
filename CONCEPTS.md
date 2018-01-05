# Pixiurge Concepts

Pixiurge runs a Demiurge simulation on the server, while putting up a
browser Javascript interface in front of it. This can turn a Demiurge
simulation into a playable browser game.

To keep things easy to understand and test, Pixiurge uses several
different layers and subsystems. How does this make it easier? By
letting you understand it in individual pieces, not all at once.

Pixiurge runs its simulation and displays the results in the browser
continually. It accepts control information from the browser and feeds
the resulting player actions into the simulation. Pixiurge also takes
care of simple accounts, logins and authentication.

Pixiurge intentionally borrows a lot from ManaSource-engine and
similar games like The Mana World, Land of Fire and Source of Tales,
as well as OpenGameArt.org and the Liberated Pixel Cup. It uses those
art styles and sprite sizes, of course. Pixiurge also uses the
ManaSource-specific subformat of TMX files and Tiled editor data. See
http://mapeditor.org for more about Tiled.

## Demiurge and Players

Demiurge is a world simulation, and Pixiurge mostly stays out of it. A
Demiurge engine should mostly run the same whether it's hooked up to a
display library or not... Except for players and their
actions. Pixiurge translates in-browser actions to Demiurge actions.

A player is normally, but not always, represented by a Demiurge item
called an Agent. The human player's browser input turns into Agent
actions.

Certain administrative actions may turn into more exotic actions. New
Demiurge items might be created or non-Agent actions might occur, for
instance. A statedump or server reboot won't normally happen as an
Agent action, for instance.

But in general, a player's UI actions will turn into queued actions in
Demiurge, and Pixiurge is how that happens.

## Software Architecture

The Demiurge engine runs inside a Ruby server which uses Websockets to
talk to the connected browsers. This is the same server that also
provides assets like maps, Javascript, graphics and sounds.

The websockets are connected to a browser, which can send control
information *to* the server and receives simulation and feedback
information *from* the server. Pixiurge has its own simple JSON
messages that it uses to communicate back and forth between browsers
and the server.

A Demiurge engine knows how objects act -- it knows how often a
particular Agent moves, or what it says. It does *not* know how they
look, such as whether a particular pictures goes with a particular
agent or room. Pixiurge is the adapter to make the Demiurge world
visible on a screen.

What are the major parts of a Pixiurge server?

* The Demiurge engine, which runs on the server; this calculates the in-game world
* The EngineSync, which watches Demiurge and notifies everything about what happens inside
* DisplayObjects, which keep track of how Demiurge objects get shown to human players
* Player objects, which keep track of what DisplayObjects have been seen and know the JSON protocol
* Browser-side Javascript code, to actually show everything to the human player

## The Cycle of Simulation

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

## DisplayObjects on the Server, SpriteStacks on the Client

A Pixiurge server is providing a lot of views into Demiurge, for a lot of
different clients, at a lot of different times. The same zone or room
looks different to different players, as you'd expect it to.

There is one single Demiurge engine on the server, with one copy of
each unique item. When it a Demiurge item changes, several different
players may be able to see it, and may receive updates to show the
change in their browser.

Pixiurge keeps a single server-side DisplayObject for each potentially
visible Demiurge object (and for some that will never be visible.)
When each DisplayObject changes, it may send updates to a bunch of
players who can see it. So: each Demiurge item has a matching
server-side Pixiurge DisplayObject.

When the Demiurge item changes, it sends a Demiurge notification. The
single, server-side EngineSync object subscribes to all Demiurge
notifications and provides all the players with a constant, consistent
view of what's happening by translating the notifications into
Pixiurge messages over Websockets. The browsers, when they get the
messages, will show the human players what changed for that Demiurge
item.

A particular browser will have items representing some of the
DisplayObjects in Pixiurge. These in-browser objects include
"spritestacks", which may have multiple layers of tiled sprites. For
instance, a ManaSource-style humanoid like a player or enemy will
normally be several layers of "grids", where each grid is (usually) 1
sprite by 1 sprite, and each sprite is 64x64. The multiple layers, if
present, are for things like hair, clothing and equipment which are
modeled as overlaid layers.

## Three Layers of Snapshots: Demiurge, DisplayObjects, the Browser

Notifications can cause some complications - more than one thing can
happen to an item during a single tick, for instance. And
notifications go out in a big batch after the tick is over, not
immediately as things happen. So when Pixiurge is processing a
notification, the item's condition may have changed in the mean
time. The player is seeing the old pre-notification state. The
notification tells what happened. But the item may have changed again
in a later notification, so we can't assume we're just updating it to
the Demiurge latest. This makes things a little complicated for
EngineSync. It can't just get the latest state from Demiurge, because
that may not be the state it wants or shows.

We also can't assume every player sees the DisplayObject the same way,
even if they're up to date. If Bob and Jane are standing in two
different parts of the same room, Bob may be able to see different
items than Jane, and they're scrolled to different positions. If Jane
has a better "perception" in some way than Bob, she may even see
things that, in effect, don't exist at all for Bob, and which may not
get sent to his browser.

## DisplayObjects and Players

A Pixiurge "Player" object is a server side object that coordinates
what gets sent to a particular browser. It may not correspond to a
single humanoid creature, or any creature or entity at all. A "Player"
could be an observer with no body, for instance.

But something has to coordinate important questions like "has this
browser received the necessary information to display this Sprite
Stack before?" and "is the browser currently showing a location where
this action is visible?" That "something" is called a "Player" by
Pixiurge.

When a DisplayObject changes (e.g. is created or destroyed or moved or
changes its display) then the various Player objects need to be
updated and send messages to the browser so that those actions can be
shown to the human viewers.

Several objects are involved in this process. The EngineSync object
sees the notification from Demiurge and makes appropriate calls to the
various DisplayObjects to let them know they've changed.
