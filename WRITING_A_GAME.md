# Writing a New Game with Pixiurge

You'd like to set up a new game with Pixiurge? Great! Let's talk about
what Pixiurge can do for you, what it makes easy and what will be more
challenging.

## What You'll Need

I'm assuming you already know Ruby pretty well. A Pixiurge app is about as
hard to build as a Ruby on Rails app - not massively hard, but you'll
need to be a decent computer programmer. If you're not a computer
programmer, you probably need to find one.

(A non-computer-programmer can certainly help. In fact, most of the
work of building a game isn't computer programming at all - it's art,
sounds, text, storytelling and so on. But Pixiurge assumes you have a
computer programmer on the project too. If you don't, and you don't
want to, then Pixiurge probably isn't for you.)

Pixiurge is still new and raw. So you'll need a programmer willing to
deal with a few sharp edges and dig in. Sorry! Every project starts
somewhere.

You or your programmer will need to know Ruby and Javascript. Ruby
runs on the server, and Javascript (mostly) runs in the browser. You
don't need to know Ruby on Rails, though it won't hurt.

## How-To

To begin with, install Pixiurge if you haven't: "gem install pixiurge"
will do it, or you can add Pixiurge to your Gemfile and run "bundle
install". You'll need Ruby for this - you already have Ruby installed,
yes?

Once you have Ruby and Pixiurge installed, you can type "pixiurge
game\_name" at the command line. Use your own game name instead of
"game\_name". It doesn't need to be final and perfect or anything -
again, the programming isn't the hard part, and you'll be able to
change it later if you need to.

Have a look around. This is a browser game, so a lot is set up around
directories full of things a browser will want - static assets like
tmx files and Javascript, an index.html file, stuff like that.

The Pixiurge library itself isn't inside your new game
directory. You'll be using it from a gem. Your Gemfile already uses it
and that's enough.

To look up stuff about Pixiurge and Demiurge, you'll want to have a
look at their documentation:
"https://noahgibbs.github.io/pixiurge". That documentation is checked
into the Pixiurge "docs" directory, so you can also look for it there.

The "world" directory is where you're going to be spending a *lot* of
quality time. It's where the world simulation code lives. Demiurge is
the world simulator library - it loads up the World File code and
keeps track of creatures moving around and stuff. Pixiurge is the
display library on top of it - it lets you run a server and use a web
browser to walk around in that world.

## Learning About Everything

You'll want to read [a bunch of
documentation](https://noahgibbs.github.io/pixiurge). It's not a bad
idea to find an example game, especially if you can find one that's
like what you want to build.

But right now, there aren't many good examples. So you probably want
to read the documentation, mostly. You can also read the Demiurge and
Pixiurge code, which are 100% free and open.

### Parts of Everything

There are a lot of things you can do. You won't need to do all of them
for most games.

Want to make a new *kind* of thing display? First, make sure you know
what the old ones are -- sometimes you can just use an existing thing
to do what you want. But for nearly any project you'll need to learn
how to add a message to Pixiurge's protocol, and write some Javascript
code to display your new thing. You may need to learn how to write
PIXI.js code to display what you want to display.

Want to make things *act* a new way? Learn about Demiurge, the
simulation library. And learn about Ruby if it's new to you. Something
like "Learn Ruby the Hard Way" or the Pickaxe Book could help you
figure out Ruby solidly.

For almost any game you'll need to find or make some assets -
pictures, sounds, maps. That's a significant undertaking and I can
only tell you a little about it. See the "Assets" section of this file
for a few more details.

### The Programmer's Interface

It's a good idea to make a new Pixiurge app and then just look up the
its code in the API documentation. That will show you a bunch of
things you could do. Along with classes and methods, your new code
contains things like Protocol messages, Notifications and
Intentions. The CONCEPT documentation for both Pixiurge and Demiurge
can help a bit with knowing what all the pieces are.

It's not a bad idea to look through the Pixiurge or Demiurge source
code. There's not a huge amount of it, and it will definitely show you
what you can do. Also, you may need to add something to
Pixiurge... Don't be afraid to jump in with a pull request, or even to
fork your own separate version of Pixiurge for your own game.

## Major Decisions

There's always more to decide. But let's talk about some important
parts.

### Ticks

You'll need to decide how often to have "ticks." By default, you'll
get 500 milliseconds per tick, or two ticks per second,
automatically. These ticks advance on a timer while the server is
running. That means:

1) If you measure time in Ticks for your simulation, that's the speed.
2) Time doesn't advance when your server isn't running.

You'll also get an autosave of the simulation engine data every 600
ticks by default. You can change the number of ticks or turn off
autosave. Every 600 ticks and 500 ms/tick means you'll get an autosave
every five minutes (300 seconds) by default.

If you set ms\_per\_tick to zero, there won't be a timer. If you want
to advance the simulation engine by a tick, you'll need to do it
yourself. You should do this if you want more control over how time
flows in your game.

You also won't automatically get "catch up" ticks if your server isn't
running and you restart it. Instead, time will stop while the server
is stopped, and pick up where it left off when you start again.

If you want to be able to "pause", that's usually done with world-file
actions. For instance, don't let a player move when the pause is
happening. If you pause the whole simulation engine, that means
*nobody* can do anything, not just one player or group of players.

## Assets

There are many kinds of assets - graphics, sound, map files. And
that's not counting things you can do in code. What's the right way to
handle that?

You can:

* Do it yourself. This will likely involve reading and practice, and
  maybe buying software.

* Have somebody else do it. If you're not paying them, don't expect
  this to go well and happen quickly.

* Restrict yourself to what you can find for free. This option gets
  easier every year, and it's a great starting place for the other two
  options as well.

What hardware and software are necessary? For graphics, there are some
great free 2D drawing programs like Medibang and Krita. Tiled is a
wonderful free map editor. There are great free animation programs
like Spriter (non-Pro version). With a microphone and Audacity, you
can do quite a lot. You can even get free image-processing programs
like The GIMP. And if you're willing to pay a bit of money, you can do
even better with programs like Affinity Designer, up through expensive
and amazing options like the Adobe Creative Suite ($50/month, but it's
used by basically all serious artistic professionals -- of whom I am
not one.)

In general, you'll need to pick one or more programs to match the
artistic style of what you're trying to make. And you and/or your
artistic team will need to use them, preferably so that the results
all look vaguely similar to each other.

### In General

I recommend OpenGameArt.org for all kinds of things. Graphics and
sounds are available and decently searchable -- make sure you get a
license you can use!

### Maps

It's worth picking up the Tiled map editor and doing some browsing of
OpenGameArt.org for graphics. Maybe you can find something close to
what you want and modify it from there?

You can find great Tiled maps out there if you look - the Kenney
dungeon tile set, for instance, comes with TMX files for Tiled. And
games that use Tiled (Source of Tales, The Mana World, etc.) often
have very nice maps you can start looking at. Keep in mind how the
licensing works - Kenney's stuff is CC0 (do whatever you want) but
many other games may need attribution, or require you to re-share or
may prevent commercial use.

And if you can find these free graphics, so can other folks. Which
means if they see it in your game they'll know whether you're using it
illegally. Graphics and maps are hard to hide. Try to use graphics
only in ways that are permitted, or use graphics like Kenney's that
can be used in any way.

### Graphics

I like the Aseprite editor for making sprites and animations, but
there are lots of good ones. Photoshop is the gold standard here, but
it's not especially cheap if you're not a professional.

Pixiurge is best for bitmap graphics, not vector graphics - so vector
images like SVGs, SWAs, FLAs and AI files will all be hard to use.

Check out OpenGameArt for useful source material, as long as the
license is compatible with what you want to do.

## Licensing

Let's talk a bit about licensing. It's a huge topic, but we can hit
the highlights.

The short version of licensing is "whoever creates a thing gets to
decide how it's used." If they sell it to somebody, of course, then
the new owner gets to decide.

### Proprietary Assets/Code

If a company or a professional author/illustrator makes something,
they don't usually let you use it how you want. You can't just take a
Disney picture of Mickey Mouse, or characters from The Lord of the
Rings or text from a John Steinbeck book and make money off them.
Those assets are all under restrictive copyrights, and you're better
off avoiding them.

There's a (small) exemption in the United States for "Fair Use," which
is a *very* legally blurry category. You can't use very much from any
particular work, but it's not clear how much. You're more likely to be
found guilty of infringement if you charge money, but it's not clear
how much more likely. Fair Use is hard to understand, and usually a
bad idea to count on.  If possible, just avoid other people's assets.

In the USA, you have a nearly unlimited ability to do parody and
satire. In many other places (e.g. Germany) you don't. What if you're
in the US and you have players in Germany? I have no clue, I am *so*
not a lawyer... I might try to avoid it anyway, you know?

If *you* make something and it's not based at all, even a little, on
somebody else's work, you can decide the license for yourself. Which
means *you* could make it proprietary.

If you want your game to be proprietary, don't use anybody else's
assets. Or pay a license fee for assets to use. And you can use CC0 or
Public Domain assets with anything, including your proprietary game
(see below.) In general, "proprietary" is how companies do it -- and
you'll notice that nobody except Disney uses Disney's assets without
paying.

### CC0 Assets and Code; Public Domain

There's a great group called "Creative Commons" that make legal
licenses for "open" assets - assets you can use for your own
projects. I have huge respect for them. Creative Commons is awesome.

The most extreme version of this is the "CC0" license, or "Creative
Commons Zero." It mimics the public domain. It's not clear that in the
United States you're allowed to just declare a thing to be in the
public domain (you can in some countries) and so CC0 is a
United-States-compatible way to do that. If something is released as
CC0, anybody can use it for any purpose as though it were in the
public domain.

Any artwork or writing older than around 1920 in the United States is
already public domain, as are certain things done for the government
-- that's why NASA images are public domain, for instance. Some more
recent works are also in the public domain if the copyright was never
renewed - the later writing of H.P. Lovecraft, for instance.

You'll also see a few AWESOME artists releasing stuff as CC0 or Public
Domain. You can use their work for absolutely anything you
like. Kenney Vleugels (Kenney.nl) and Hyptosis (Lorestrome.com) both
release CC0 work, for instance. I use their stuff regularly.

CC0 is great for using with any other license. If you release *your*
assets as CC0 you'll probably get less credit and you'll definitely
get less money for it. But the assets you release may be *used* all
over the place. Which is why we're so grateful to the folks that do
it.

### Creative Commons

There are a bunch of other Creative Commons licenses. The creator
decides what rights to give you (the user) and what rights to
keep. You'll normally see it as something like "CC 3.0 BY-SA", which
means "Creative Commons license version 3.0 with 'BY' and 'SA' as the
extras."

What kinds of extras? Any of these, basically:

* BY or "attribution": this means you have to say where you got
  it. Erfworld.com uses CC 3.0 BY-NC and so if you use their work, you
  have to add a little "Graphics Copyright Erfworld.com" disclaimer
  somewhere.

* SA or "sharealike": you have to give other folks the same rights you
  got. So you can't take any rights away from later people you give it
  to if you got those rights. So if you build a commercial game on top
  of CC 3.0 BY-SA content, you have to let other people download and
  use your graphics, even if you made changes to them.

* NC or "noncommercial": this one is annoyingly vague, even in their
  legal license. They're trying to say you can't charge money for the
  result - so you can build a *free* game with Erfworld's CC 3.0 BY-NC
  comics, but you can't charge money for that game.

The most common good free assets tend to be Creative Commons. The
author can let you use their stuff but require you to give them
credit. The Liberated Pixel Cup is a great specific instance of CC 3.0
BY-SA that you can use for commercial games *if* you give appropriate
credit (and you should.)

Keep in mind that with an attribution (BY) license, you may wind up
having to credit a LOT of people. The way games like Source of Tales
or The Mana World deal with this is to have an AUTHORS file with a
long list of all their graphics and sounds and who gets credit for
each individual image. That sounds kind of extreme. But if you use a
lot of CC 3.0-BY licensed assets, you *have* to do something like
that.

### GNU General Public License ("GPL")

The GPL is originally for software. It says that if you "link" with
some code under GPL, you have to give away *all* your code under the
GPL. That means you have to give it all away, but it also means that
anybody you give it to can't use it *without* giving it all away.

It's not always clear what "linking" means under GPL, even with
software. It's also not clear what the even-more-restrictive GPL 3.0
requires, since you have to give away software even if it's running on
a different server... But *when* exactly? Not clear.

"Linking" is even less clear with graphics than with computer
code. And a lot of the GPL license is written with code in mind, and
talks about code, not assets.

Realistically, if your *code* is also GPL, there's nothing wrong with
using GPL graphics. But it's not obvious what "GPL graphics" actually
*do* if somebody wants to use your graphics and *not* use your code.

If you make anything new, I recommend using a different license like
Creative Commons instead of GPL. Using a CC 3.0 BY-SA license will
give you what you want (they have to give you credit and share changes
to your graphics) without the confusion of trying to apply the GNU
General Public License to something that isn't source code.

There is at least one more GNU license I know of that *is* designed
for creative assets instead of code - the GNU Free Documentation
License. I don't know much about it, and I've never seen anything in
the wild that uses it that isn't from GNU itself. I can't give you a
useful contrast between the GNU FDL and CC 3.0 BY-SA. But those two
seem similar to each other, at first glance.

### Derived Works

If you start from somebody else's work, you're making a "derived work"
- it's not all yours and it's not all theirs, but some murky
in-between. If they gave you permission to do this (CC0 license, CC
3.0 BY-SA license, GPL, etc) and you license it the same way, then
all's well. If you don't share the derived work with anybody except
yourself, you're fine. But if you want to change the license, that's
murky legal territory. Sometimes it works (you can relicense CC0 as
*anything*) and sometimes it doesn't (you can't turn GPL into CC0.)

In general, try to keep the license the same. Are you starting from
GPL'd assets and code? Great, make a GPL'd result. CC BY-SA? Great,
make your thing CC BY-SA as well and add your name to the
contributors. Starting from CC0? Do whatever you want.

### Compatibility

You can't always use multiple assets together. My opinion (I am not a
lawyer):

* You can use CC0 with anything and do whatever you want with it. It
  goes with anything and relicenses as anything.

* If you're giving the results away and you're careful to say what
  stuff you used from other people, CC 3.0 is great with any of BY or
  SA. Be careful with NC ("NonCommercial") since Creative Commons has
  never spelled out clearly what that means. So it's hard to say what
  it's compatible with.

* GPL: man, who knows? Does using a set of graphics with other
  graphics count as "linking" them? Do you have to give away source
  code to your entire game? Can you put GPL'd graphics in a
  spritesheet with CC BY-NC, or is that illegal? The GPL was *not*
  designed for assets, which makes these *very* sticky questions. I'd
  want to talk to a lawyer before doing them, which is why I DO NOT
  USE assets under GPL. I've read the license very carefully. These
  are hard questions.

In general, I recommend picking a license you're okay with. See above
for how that works with just one license. Plus you can use CC0 content with
any other license, however you want.

## Philosophical Advice

### Pixiurge is Opinionated

Pixiurge gives pretty strong defaults for how it thinks games should
look. As a result, it can be very easy to set up a simple game... if
you do it how Pixiurge expects. The more you deviate from what
Pixiurge already does, the more work you'll have to do to make it
happen.

So: what are its opinions?

First off: Pixiurge only does browser games. If you want to write a
native mobile game or a Windows game or something, Pixiurge won't help
you.

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
