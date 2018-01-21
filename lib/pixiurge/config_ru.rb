require "faye/websocket"
require "rack/coffee"

# No luck with Puma - for now, hardcode using Thin
# @todo move this into Pixiurge.rack_builder?
Faye::WebSocket.load_adapter('thin')

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
    @rack_builder.use(Rack::Static, :root => coffee_root, :urls => ["/vendor"]) unless options[:no_vendor_pixiurge]
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
  # @param dirs [String, Array<String>] One or more directories to serve TMX files from
  # @param options [Hash] Optional final options after directories
  # @option options [Demiurge::Tmx::TileCache] Optional TMX TileCache to use; defaults to TmxLocation.default_cache
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
  # JSON format that it exports. By converting the (static) TMX file
  # and giving appropriate checksums and cache headers, you can make
  # virtual-static exported JSON TMX files with sane caching and
  # reload behavior directly from a standard XML TMX file.
  #
  # @since 0.1.0
  class TmxJson
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
    # @since 0.1.0
    def call(env)
      # If no TMX path is matched, forward the call to the next middleware
      call_root = matches_url(env["PATH_INFO"])
      return @app.call(env) unless call_root

      # Okay, a TMX root was matched...

      local_path = File.join(@root, env["PATH_INFO"])
      json_local_path = local_path.sub(/\.json$/, ".tmx")
      existing = [local_path, json_local_path].detect { |f| File.exists?(f) }
      unless existing
        return [404, {}, [""]]
      else
        tmx_map = Tmx.load(existing)
        json_contents = tmx_map.export_to_string :filename => existing, :format => :json
        return [200, { "type" => "application/json" }, [ json_contents ] ]
      end
    end

    private

    def matches_url(path)
      @urls.detect { |u| path.index(u) == 0 }
    end

  end
end
