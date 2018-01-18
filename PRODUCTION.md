# So You Want to Put It Into Production...

Getting a Websocket-aware game with a Ruby server into production has
a lot of pieces to get right. It'll help if you've done this sort of
thing before. But even the pros can use a checklist. I can't provide
you a fully complete list, but here are some of the things to look
into for your deployment...

* Pixiurge REQUIRES secure sockets. The dev versions uses a
  self-signed certificate, but you'll need a production certificate
  that matches your domain. Otherwise all your users will have to
  manually configure their web browsers to accept self-signed certs,
  which is NOT OKAY.

* You'll need a nice recent version of Ruby, which probably means
  using rvm to compile one. There may or may not be a good one for
  your Linux distribution of choice. For preference use the same
  version of Ruby you've been developing with.

* Pixiurge is deployed on Thin, a Ruby application server. You'll
  either need to look into production settings for it (for instance,
  how many threads?) or figure out how to run Pixiurge on another app
  server like Puma.

* There is no reason to run Pixiurge as root. Don't do it. But make
  sure permissions are set up properly.

* Most commonly, Pixiurge writes local files to its directory for
  things like accounts and state. You'll need to back these up
  regularly. If you want to use a database or something, you'll need
  to make sure Pixiurge is configured for that, which it isn't right
  out of the box.  You'll *still* need to back them up regularly.

* A development Pixiurge install sometimes loads a lot of unminified
  Javascript. Make sure it got switched to requiring a single minified
  release version.
