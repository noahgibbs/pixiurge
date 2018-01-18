# Pixiurge

Pixiurge provides a Websocket- and PIXI.js-based browser game front
end for a Demiurge simulation engine.

Demiurge is a library for easy creation of game rules and behavior
using Ruby. Demiurge stays powerful, simple and easy to test by only
handling simulation, not display. Pixiurge leaves the simulation to
Demiurge and displays the result.

Pixiurge's tech stack includes:

* Pixi.JS
* Demiurge
* Websockets using Faye and EventMachine
* CoffeeScript
* The Tiled Sprite Editor and its format (TMX/TSX format, TMX JSON format)

Pixiurge is intended for creating simulation-heavy browser games that
don't need fast response -- it's for interactive novels and simulated
gardens, not "twitch" games.

## Getting Started

Whether you're getting up to speed on an existing Pixiurge project or
starting a new one, documentation is important. See
[the documentation page](https://codefolio.github.io/pixiurge) for
various good starting points and
[the API documentation](https://codefolio.github.io/pixiurge/pixiurge).

## Installation

For creating a new Pixiurge-based project, see "Usage" below.

To add Pixiurge to an existing app directory, add this line to your
application's Gemfile:

```ruby
gem 'pixiurge'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pixiurge

## Usage

Ordinarily you'll use Pixiurge by creating a new game or similar
gamelike application that uses the Pixiurge gem. Add "pixiurge" to
your gemspec or Gemfile to include Pixiurge. Make sure to run
"bundle".

This gem includes a sample config.ru file, showing how to serve the
appropriate HTML and JavaScript content for your browser-based game
client and to connect your evented game server via websockets.

Your software will run via an app server, either Thin or Puma.

    $ thin start -R config.ru -p 3001

For most applications you'll want to run with SSL configured -
Pixiurge does *not* handle over-the-wire security for you, it assumes
that SSL/TLS will take care of that problem. See example/start_server
for an example of how to make sure SSL is set up when running your
server locally.

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
