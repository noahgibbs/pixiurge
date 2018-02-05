require "faye/websocket"
require "rack/coffee"

require "pixiurge"

class Pixiurge::App
  # Call this with your application's web root directory.
  # This is useful for finding your application's assets,
  # such as graphics, images and maps. Later calls such
  # as static_dirs and coffeescript_dirs are relative to
  # this root.
  #
  # @param dir [String] The path to your app's web root.
  # @since 0.1.0
  def root_dir dir
    @root_dir = File.absolute_path(dir)
  end

  # In config.ru, call this as "Pixiurge.rack_builder self" to allow Pixiurge to
  # add middleware to your Rack stack. Pixiurge will add its own /pixiurge directory
  # in order to provide access to the Pixiurge debug or release Javascript.
  #
  # @param builder [Rack::Builder] The top level of your config.ru Rack Builder
  # @param options [Hash] Options about Rack middleware
  # @option options [Boolean] :no_dev_pixiurge Don't automatically host the Pixiurge unminified Javascript at /pixiurge
  # @option options [Boolean] :no_vendor_pixiurge Don't automatically host the Pixiurge vendor scripts at /vendor
  # @since 0.1.0
  def rack_builder builder, options = {}
    illegal_opts = options.keys - [ :no_dev_pixiurge, :no_vendor_pixiurge ]
    raise("Unknown option(s) passed to rack_builder: #{illegal_opts.inspect}!") unless illegal_opts.empty?
    @rack_builder = builder

    coffee_root = File.expand_path File.join(__dir__, "..", "..")
    vendor_root = File.join(coffee_root, "vendor")
    @rack_builder.use(Rack::Coffee, :root => coffee_root, :urls => ["/pixiurge"]) unless options[:no_dev_pixiurge]
    @rack_builder.use(Rack::Static, :root => coffee_root, :urls => ["/vendor", "/pixiurge"]) unless options[:no_vendor_pixiurge]
  end

  # Call this to add coffeescript directories for your own app, if you're using
  # CoffeeScript.
  #
  # @param dirs [String, Array<String>] The directory name or array of directory names, located under the web root you passed to Pixiurge.root_dir
  # @since 0.1.0
  def coffeescript_dirs *dirs
    raise "Please set Pixiurge.root_dir before using Pixiurge.static_dirs!" unless @root_dir
    dirs = [*dirs].flatten
    @rack_builder.use Rack::Coffee, :root => (@root_dir + "/"), :urls => dirs.map { |d| "/" + d }
  end

  # To have Pixiurge serve static directories of Javascript or assets,
  # call this with the appropriate list of directory names.  All
  # directory names are relative to the web root you passed to
  # Pixiurge.root_dir. It's possible to call this multiple times, but
  # then you'll get a tiny inefficiency where two different Rack
  # middlewares get checked. Not a big deal if you have a reason, but
  # it's slightly better to call it once with a list of directories.
  #
  # @param dirs [String, Array<String>] The directory name or array of directory names, located under the web root you passed to Pixiurge.root_dir
  # @since 0.1.0
  def static_dirs *dirs
    dirs = [*dirs].flatten

    raise "Please set Pixiurge.root_dir before using Pixiurge.static_dirs!" unless @root_dir
    @rack_builder.use Rack::Static, :root => @root_dir, :urls => dirs.map { |d| "/" + d }
  end

  # To have Pixiurge serve individual static files such as index.html, call this with the appropriate list of file paths.
  # All paths are relative to the web root you passed to Pixiurge.root_dir.
  #
  # @see Pixiurge.static_dirs
  # @param files [String, Array<String>] The file path or array of file paths, located under the web root you passed to Pixiurge.root_dir
  # @since 0.1.0
  def static_files *files
    @static_files ||= []
    @static_files.concat [*files].flatten
  end

  # To serve some specific file from the root, a redirect is one
  # possibility. This will redirect from "/" to the given URL
  # with an HTTP status 302.
  #
  # @param url [String] The URL to redirect to
  # @since 0.1.0
  def root_redirect url
    @root_redirect = url
  end

  # To serve various template file types, the Tilt middleware can be
  # used.  This is for things like Erb or Haml that can generate HTML,
  # but can also work for CoffeeScript and other file types.
  #
  # @param dirs [String, Array<String>] One or more paths to treat as tilt dirs; relative to Pixiurge.root_dir
  # @param options [Hash] Optional final Hash with which to supply options to the Tilt middleware
  # @option options [Array<String>] :engines What template types to allow from the Tilt-provided list of template types; default: ["erubis"]
  # @return [void]
  # @since 0.1.0
  def tilt_dirs *dirs
    options = {}
    options = dirs.pop if dirs[-1].respond_to?(:has_key?)
    dirs = [*dirs].flatten
    raise "Please set Pixiurge.root_dir before using Pixiurge.tilt_dirs!" unless @root_dir
    @rack_builder.use Pixiurge::Middleware::Tilt,
      :root => @root_dir,
      :urls => dirs.map { |d| "/" + d },
      :scope => Pixiurge::TemplateView.new,
      :engines => options[:engines] || ["erubis"]
    nil
  end

  # The Tiled map editor strongly prefers keeping its map data in TMX,
  # an XML-based format. Unfortunately, JSON is *much* better for use by
  # Javascript. Since TMX has a standard JSON export format, we
  # preconvert the TMX to JSON on the Ruby side to keep the structures
  # and field names the same. TMX and TMX-JSON have some unfortunate
  # structure and naming differences, so it's not trivial to convert
  # between them.
  #
  # It's possible to use Tiled to export from TMX to JSON on the
  # command line, but TMX is a graphical program and can be hard to
  # build on a server - we'd rather not have it as a runtime dependency.
  #
  # This middleware uses the Ruby tmx gem to on-the-fly convert between
  # XML-based TMX data and an approximation of Tiled's JSON TMX format.
  # The current converter is somewhat limited - if we need a closer match
  # in the future, the plan is to submit pull requests to the tmx gem
  # until its approximation of Tiled's behavior is good enough.
  #
  # If the final argument appears to be a Hash, it will be treated as
  # an options hash. If it contains the key :cache, the value of that
  # key should be a {Demiurge::Tmx::TileCache} to use when querying
  # TMX data. It defaults to TmxLocation.default_cache.
  #
  # @param dirs [String, Array<String>] One or more directories to serve TMX files from
  # @return [void]
  # @since 0.1.0
  def tmx_dirs *dirs
    options = {}
    if dirs[-1].respond_to?(:has_key?)
      options = dirs.pop
    end
    dirs = [*dirs].flatten
    raise "Please set Pixiurge.root_dir before using Pixiurge.static_dirs!" unless @root_dir
    @rack_builder.use Pixiurge::Middleware::TmxJson,
      :root => @root_dir,
      :urls => dirs.map { |d| "/" + d },
      :cache => Demiurge::Tmx::TmxLocation.default_cache  # By default, use the same cache TmxLocations do
    nil
  end

  # Get the final, built Rack handler from Pixiurge with all the specified middleware and websocket handling.
  #
  # @see Pixiurge.root_dir
  # @see Pixiurge.static_dirs
  # @see Pixiurge.coffeescript_dirs
  # @since 0.1.0
  def handler
    @static_files ||= []
    static_files = @static_files.map { |f| "/" + f }
    lambda do |env|
      if Faye::WebSocket.websocket? env
        ws = Faye::WebSocket.new(env)
        return websocket_handler(ws).rack_response
      else
        if @root_redirect && env["PATH_INFO"] == "/"
          return [302, { 'Location' => @root_redirect }, [] ]
        end
        if @root_dir && static_files.include?(env["PATH_INFO"])
          file = env["PATH_INFO"]
          path = File.join(@root_dir, file)
          # @todo Figure out how to do this with Rack::File instead of File.read
          return [200, {'Content-Type' => 'text/html'}, [File.read(path)]]
        else
          return [404, {}, [""]]
        end
      end
    end
  end
end

# Middleware modules for Pixiurge. This allows custom serving of
# assets. Pixiurge also uses off-the-shelf middleware like
# Rack::Static and Rack::Coffee to serve common asset types.
#
# @since 0.1.0
module Pixiurge::Middleware

  # The TmxJson middleware reads TMX files in the normal XML mode that
  # Tiled loads and saves easily, but serves it in the AJAX-friendly
  # JSON format that Tiled exports. This allows JavaScript-friendly
  # usage directly from a standard XML TMX file without the manual
  # export step every time.
  #
  # @since 0.1.0
  class TmxJson
    # Constructor. Rack has a standard format for these, though the
    # options are specific to the TmxJson middleware.
    #
    # @param app [Rack::App] The next innermost Rack app
    # @param options [Hash] Options to this middleware
    # @option options [String,Array<String>] :urls A root or list of URL roots to serve TMX files from
    # @option options [String] :root The file system root to serve from (default: Dir.pwd)
    # @option options [Demiurge::Tmx::TileCache] :cache The tile cache to serve from; use this option to share or clear the cache from elsewhere
    # @since 0.1.0
    def initialize(app, options = {})
      @app = app
      @urls = [(options[:urls] || "/tmx")].flatten
      @root = options[:root] || Dir.pwd
      @cache = options[:cache] || ::Demiurge::Tmx::TmxCache.new(:root_dir => @root)
    end

    # The Rack .call method for middleware.
    #
    # @param env [Hash] The Rack environment hash.
    # @since 0.1.0
    def call(env)
      # If no TMX path is matched, forward the call to the next middleware
      call_root = matches_url(env["PATH_INFO"])
      return @app.call(env) unless call_root

      # Okay, a TMX directory was matched...

      local_path = File.join(@root, env["PATH_INFO"])

      # Check for a .tmx.json, .manasource.json or .conv.json
      json_local_path = local_path.sub(/\.([^.]+)\.json$/, ".tmx")
      subformat = $1
      existing = [local_path, json_local_path].detect { |f| File.exists?(f) }
      unless existing
        return [404, {}, [""]]
      else
        if existing == local_path
          # Whatever it is, it's a path that literally exists right there.
          return [ 200, {}, Rack::File.new(existing) ]
        elsif subformat == "conv"
          tmx_map = Tmx.load(existing)
          json_contents = tmx_map.export_to_string :filename => existing, :format => :json
          return [200, { "type" => "application/json" }, [ json_contents ] ]
        elsif subformat == "tmx"
          return [200, { "type" => "application/json" }, [ MultiJson.dump(@cache.tmx_entry("tmx", existing)) ] ]
        elsif subformat == "tmxpretty"
          return [200, { "type" => "application/json" }, [ MultiJson.dump(@cache.tmx_entry("tmx", existing), :pretty => true) ] ]
        elsif subformat == "manasource"
          return [200, { "type" => "application/json" }, [ MultiJson.dump(@cache.tmx_entry("manasource", existing)) ] ]
        elsif subformat == "manasourcepretty"
          return [200, { "type" => "application/json" }, [ MultiJson.dump(@cache.tmx_entry("manasource", existing), :pretty => true) ] ]
        else
          # Okay, no clue what they're asking for even though we have a matching .tmx file.
          return [404, {}, [""]]
        end
      end
    end

    private

    def matches_url(path)
      @urls.detect { |u| path.index(u) == 0 }
    end

  end

  require "tilt"

  # The Tilt middleware serves Tilt (template) directories. See
  # https://github.com/rtomayko/tilt for the list of supported
  # template engines.
  class Tilt
    MIME_TYPE_EXTENSION_MAP = {
    }

    # Constructor. If you supply a list of engines, you'll need to
    # make sure the appropriate gems are included for them.  For
    # instance if you supply "haml" as an engine, make sure to include
    # the "haml" gem for your game.
    #
    # This can be used to serve Ruby template files like Erb or Haml,
    # but also Markdown, CoffeeScript, TypeScript, LiveScript, Less,
    # Sass/Scss and more with the right gems. See
    # https://github.com/rtomayko/tilt for the list of supported
    # template engines.
    #
    # For templating libraries like Erb that can handle any file type,
    # this middleware will *strip* extensions.  That means something
    # ending in ".html.erb" will only be served if you ask for the
    # same with ".html". You can do the same with something like
    # CoffeeScript, so you could name your files
    # whatever_filename.js.coffee if you want them to be converted to
    # JS and served with a .js extension. But the middleware will also
    # try to use sane extensions (convert .coffee to .js, etc) where
    # it can. If you have trouble, try manually using the "stripped"
    # extension trick (e.g. my_file.js.coffee or my_file.html.haml).
    #
    # Note that multiple instances don't keep the extensions separate,
    # so it may be hard to keep from serving Markdown files out of
    # your Haml directory... Don't keep files in your asset
    # directories if you're worried about your users seeing them, in
    # general.
    #
    # In production it will be faster to "bake" these directories into
    # static files of the appropriate type instead of converting on
    # the server.
    #
    # @param app [Rack::App] The next innermost Rack app
    # @param options [Hash] Options to this middleware
    # @option options [String,Array<String>] :urls A root or list of URL roots to serve TMX files from
    # @option options [String] :root The file system root to serve from (default: Dir.pwd)
    # @option options [String, Array<String>] :engines List of Tilt-supported template engines to use; default: [ "erubis" ]
    # @option options [String] :encoding The string encoding for Tilt to use (default: 'utf8')
    # @option options [Object] :scope The 'scope' object for Tilt evaluation - can define methods that will be available
    # @option options [Hash] :locals Local variables to be defined inside Tilt evaluations
    # @since 0.1.0
    def initialize(app, options = {})
      @app = app
      @urls = [(options[:urls] || "/tmx")].flatten
      @root = options[:root] || Dir.pwd

      @tilt_scope = options[:scope] || Object.new
      @tilt_locals = options[:locals] || {}

      engines = []
      if options[:engines]
        engines = [options[:engines]].flatten
      else
        engines = [ "erubis" ]
      end

      engines.each { |engine_name| require engine_name }
      bad_engines = engines.select { |eng| ::Tilt[eng].nil? }
      raise("No Tilt templating engine for engine(s): #{bad_engines.inspect}!") unless bad_engines.empty?
      tilt_engines = engines.map { |engine_name| ::Tilt[engine_name] }
      # We just want the list of extensions. We're going to use Tilt's
      # default preference priorities for a given extension. If
      # somebody wants different, they're allowed to call Tilt.prefer,
      # likely from config.ru.
      @extensions = tilt_engines.flat_map { |eng| ::Tilt.default_mapping.extensions_for(eng) }.uniq

      @mapped_extensions = {}
      tilt_engines.each do |engine|
        engine.default_mime_type
      end

      @encoding = options[:encoding] || 'utf8'
    end

    # The Rack .call method for middleware.
    #
    # @param env [Hash] The Rack environment hash.
    # @since 0.1.0
    def call(env)
      # If no Tilt path is matched, forward the call to the next middleware
      call_root = @urls.detect { |u| env["PATH_INFO"].index(u) == 0 }
      return @app.call(env) unless call_root

      # A directory was matched. Let's see if we have any file which,
      # when we strip the extension, would give us the requested
      # file.
      local_path = File.join(@root, env["PATH_INFO"])
      local_extension = @extensions.detect { |ext| File.exist?(local_path + "." + ext) }
      # No match? 404.
      unless local_extension
        return [404, {}, [""]]
      end

      local_template_file = local_path + "." + local_extension

      # Caching these is faster than not. You know what's faster yet?
      # Rendering them into a nice static file and serving that via
      # NGinX. The easiest way to do that for nontrivial cases is
      # probably using 'curl' to get these from the server.
      template = ::Tilt.new local_template_file
      return [200, {}, [ template.render(@tilt_scope, @tilt_locals) ]]
    end
  end
end
