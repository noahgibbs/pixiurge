# Writing a New Game with Pixiurge

You'd like to set up a new game with Pixiurge? Great! Let's talk about
what Pixiurge can do for you, what it makes easy and what will be more
challenging.

## What You'll Need

I'm assuming you already know Ruby pretty well. A Pixiurge is about as
hard to build as a Ruby on Rails app - not massively hard, but you'll
need to be a decent computer programmer. If you're not a computer
programmer, you probably need to find one for this.

(A non-computer-programmer can certainly help. In fact, most of the
work of building a game isn't computer programming at all - it's art,
sounds, text, storytelling and so on. But Pixiurge assumes you have a
computer programmer on the project too. If you don't, and you don't
want to, Pixiurge probably isn't for you.)

Pixiurge is still new and raw. So you'll need a programmer willing to
deal with a few sharp edges and dig in. Sorry! Everything starts
somewhere.

You or your programmer will need to know Ruby and Javascript. Ruby
runs on the server, and Javascript (mostly) runs in the browser. You
don't need to know Rails, though it won't hurt.

## How-To

To begin with, install Pixiurge if you haven't: "gem install pixiurge"
will do it, or you can add Pixiurge to your Gemfile and run "bundle
install". You'll need Ruby for this - you already have Ruby installed,
yes?

Once you have Ruby and Pixiurge installed, you can type "pixiurge new
game\_name" at the command line. Use your own game name instead of
"game\_name". It doesn't need to be final and perfect or anything -
again, the programming isn't the hard part, and you'll be able to
change it later if you need to.

Have a look around. This is a browser game, so a lot is set up around
directories full of things a browser will want - static assets like
tmx files and Javascript, an index.html file, stuff like that.

The Pixiurge library itself isn't in there. You'll be using it from a
gem. You can *use* it, it's just not copied into your game.

To look up stuff about Pixiurge and Demiurge, you'll want to have a
look at their documentation: "https://noahgibbs.github.io/pixiurge".

The "world" directory is where you're going to be spending a *lot* of
quality time. It's where the world simulation code lives. Demiurge is
the world simulator library - it loads up the World File code and
keeps track of creatures moving around and stuff. Pixiurge is the
display library on top of it - it lets you run a server and use a web
browser to walk around in that world.

## Learning About Everything

You'll want to read [a bunch of
documentation](https://noahgibbs.github.io/pixiurge). It's not a bad
idea to find an example game, especially if you can find one that's a
lot like what you want to build.

But right now, there aren't many good examples out there. So you
probably want to read the documentation, mostly.

### Parts of Everything

There are a lot of things you can do. You won't need to do all of them
for most games.

Want to make a new *kind* of thing display? First, make sure you know
what the old ones are -- sometimes you can just use an existing thing
to do what you want. But if not, you'll need to learn how to add a
message to Pixiurge's protocol, and write some PIXI.js code to display
your new thing.

Want to make things *act* a new way? Learn about Demiurge, the
simulation library. And learn about Ruby if it's new to you. Something
like "Learn Ruby the Hard Way" or the Pickaxe Book could help you
figure out Ruby solidly.

For almost anything, you'll need to find or make some assets -
pictures, sounds, maps. So it's worth picking up the Tiled map editor
and doing some browsing of OpenGameArt.org. Maybe you can find
something close to what you want and modify it from there? I like the
Aseprite editor for making sprites and animations, but there are lots
of good ones. Photoshop is the gold standard here, but it's not
especially cheap if you're not a professional.

### The Interface

It's a good idea to make a new Pixiurge app and then just look up the
pieces of it in the API documentation. That will show you a bunch of
things you could do. Keep in mind that along with classes and methods,
there are things like Protocol messages, Notifications and
Intentions. The CONCEPT documentation for both Pixiurge and Demiurge
can help a bit with knowing what all the pieces are.

It's not a bad idea to look through the Pixiurge or Demiurge source
code. There's not a huge amount of it, and it will definitely show you
what you can do. Also, you may need to add something to
Pixiurge... Don't be afraid to jump in with a pull request, or even to
fork your own separate version of Pixiurge for your own game.

## Philosophical Advice

### Pixiurge is Opinionated

Pixiurge gives pretty strong defaults for how it thinks games should
look. As a result, it can be very easy to set up a simple game... if
you do it how Pixiurge expects. The more you deviate from what
Pixiurge already does, the more work you'll have to do to make it
happen.

So: what are its opinions?

First off: Pixiurge only does browser games. If you want to write a
native mobile game or a Windows game or something, Pixiurge basically
won't help you at all.

Pixiurge is set up for slower-paced simulation games, not twitch
games. Pixiurge needs a network round trip to do *anything* that
involves the server. That's fine if you're building a slow, strategic
game. It sucks if you're trying to build a multiplayer platformer or a
rhythm game or a shooter. Related: Pixiurge has a client in
garbage-collected Javascript, a server in garbage-collected Ruby, and
uses Websockets (TCP/IP) for transport. This means you *will* see
short delays at random times and sometimes _long_ delays. This is
another reason not to build your shooter or rhythm game in Pixiurge.

So what's a good example of Pixiurge-compatible gameplay? A JRPG-style
tiled game where you explore and fight could work great. A
Stardew-Valley style game where you craft or garden fits
nicely. Turn-based combat (X-COM) or conversation (The Walking Dead)
is fine. Strategy games are good.

Pixiurge normally assumes you want multiplayer. You can do some
single-player-style interactions, but... If you're bothering with a
concurrent event-based Ruby server, you probably want multiple
players. There are simpler ways to build a single-player game where
you don't use a shared server at all, right?
