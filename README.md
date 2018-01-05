# Pixiurge

Pixiurge (sometimes "PXG" for short) provides a Websocket- and
Pixi-based browser game front end for a Demiurge simulation engine.

Demiurge is a library for easy creation of game simulation and
artificial intelligence using Ruby. Demiurge stays powerful, simple
and easy to test by only doing simulation, not display. Pixiurge
leaves the simulation to Demiurge, and does the display.

Pixiurge's tech stack includes:

* Pixi
* Demiurge
* Websockets using Faye and EventMachine
* CoffeeScript
* The Tiled Sprite Editor and its format (TMX/TSX format, TMX JSON format)

Pixiurge is intended for creating simulation-heavy browser games that
don't need fast response -- it's for interactive novels and simulated
gardens, not "twitch" games.

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
that SSL/TLS will take care of that problem.

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
