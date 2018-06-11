# Pixiurge

Pixiurge provides a Websocket- and PIXI.js-based browser game front
end for a Demiurge simulation engine.

Demiurge is a library for easy creation of game rules and behavior
using Ruby. Demiurge stays powerful, simple and easy to test by only
handling simulation, not display. Pixiurge leaves the simulation to
Demiurge and displays the result.

Pixiurge's tech stack includes:

* Pixi.JS (though you can build other display technology if you like)
* Demiurge
* Websockets using Faye and EventMachine
* WebPacker for CoffeeScript and other front-end tooling
* The Tiled Sprite Editor and its format (TMX/TSX format, TMX JSON format)

Pixiurge is intended for creating simulation-heavy browser games that
don't need fast response -- it's for interactive novels and simulated
gardens, not multiplayer "twitch" games.

## Getting Started

Whether you're getting up to speed on an existing Pixiurge project or
starting a new one, documentation is important. See [the documentation
page](https://noahgibbs.github.io/pixiurge) for various good starting
points and [the API
documentation](https://noahgibbs.github.io/pixiurge/pixiurge) for a
more in-depth treatment.

## Installation

For creating a new Pixiurge-based project, see "Usage" below.

To install Pixiurge outside of a Gemfile or project:

    $ gem install pixiurge

If Pixiurge is already part of a project's Gemfile, just run "bundle"
to install all gems for that project, including Pixiurge.

## Usage

Ordinarily you'll use Pixiurge by creating a new game or similar
gamelike application that uses the Pixiurge gem. The recommended way
to do that is with the "pixiurge" command:

    $ pixiurge my_project_name

This will create a new project directory with important files and
directories set up for you. You'll want to run "bundle" to install the
appropriate gems, and you'll probably want to create a new repository
in your source control system of choice. If you use Git:

    $ git init
    $ git add .
    $ git commit -m "Initial commit"

Pixiurge projects start with a .gitignore file. Its contents may be
useful if you want to exclude appropriate files in a different source
control system.

You can find documentation on writing a new Pixiurge game in the
Pixiurge documentation, at [the WRITING_A_GAME
page](https://noahgibbs.github.io/pixiurge/pixiurge/file.WRITING_A_GAME.html).

### Security

To develop a game on Pixiurge, you'll need TLS (secure sockets.) Any
new Pixiurge game comes with a "start_server" script which will create
a local self-signed certificate so you're secure from the get-go. But
you'll need to get your web browser to let you use a self-signed
certificate with a localhost URL (or use a URL redirect - if you're
used to SSL for development on localhost, this is a familiar problem.)

I recommend Googling for "Google Chrome self-signed certificate" and
doing what it says.

## Credits

For testing and other purposes I sometimes use CC0 (Creative Commons
Zero, effectively Public Domain) artwork of various kinds. Luis Zuno
(ansimuz.com), Daniel Harris (Hyptosis, lorestrome.com) and Kenney
Vleugels (kenneynl.com, pixeland.io) all have wonderful CC0 work that
I use. With CC0 I'm not required to credit them and neither are you,
but it's good karma to pay them if you make money off their work. It's
also good karma to mention them when you use their work, as I do here.

CC0 is wonderful because I don't have to worry about licensing, at
all, full stop. Creative Commons licensing in general is awesome - I
certainly don't mind crediting people for what they do. But I want to
set any future Pixiurge users up for success, so I try to only use
assets with the least-restrictive licenses. I remember DikuMUD too
well, you know?

I do *not* use any of the wonderful free GPL-licensed artwork out
there because it's incompatible with the MIT license I use for my
open-source coding. The GPL wasn't really designed for art assets like
sprites or sound effects and it's not entirely clear how that should
work. I steer clear of GPL and try to use CC0 where possible because I
don't want to police all of you or encourage you in illegal directions.

## Development

After checking out the repo, run `bin/setup` to install
dependencies. Then, run `rake test` to run the tests. You can also run
`bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake
install`. To release a new version, update the version number in
`version.rb`, and then run `bundle exec rake release`, which will
create a git tag for the version, push git commits and tags, and push
the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/noahgibbs/pixiurge. This project is intended to be
a safe, welcoming space for collaboration, and contributors are
expected to adhere to the [Contributor
Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).
