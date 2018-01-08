require "faye/websocket"
require "rack/coffee"

# No luck with Puma - for now, hardcode using Thin
# TODO: move this into Pixiurge.rack_builder
Faye::WebSocket.load_adapter('thin')

module Pixiurge
  # Call this with your application's web root directory.
  # This is useful for finding your application's assets,
  # such as graphics, images and maps. Later calls such
  # as static_dirs and coffeescript_dirs are relative to
  # this root.
  #
  # @param dir [String] The path to your app's web root.
  # @since 0.1.0
  def self.root_dir dir
    @root_dir = File.absolute_path(dir)
  end

  # In config.ru, call this as "Pixiurge.rack_builder self" to allow Pixiurge to
  # add middleware to your Rack stack. Pixiurge will add its own /pixiurge directory
  # in order to provide access to the Pixiurge debug or release Javascript.
  #
  # @param builder [Rack::Builder] The top level of your config.ru Rack Builder
  # @since 0.1.0
  def self.rack_builder builder
    @rack_builder = builder

    coffee_root = File.join(__dir__, "..", "..")
    @rack_builder.use Rack::Coffee, :root => coffee_root, :urls => "/pixiurge"
  end

  # Call this to add coffeescript directories for your own app, if you're using
  # CoffeeScript.
  #
  # @param dirs [String, Array<String>] The directory name or array of directory names, located under the web root you passed to Pixiurge.root_dir
  # @since 0.1.0
  def self.coffeescript_dirs *dirs
    raise "Please set Pixiurge.root_dir before using Pixiurge.static_dirs!" unless @root_dir
    dirs = [*dirs].flatten
    @rack_builder.use Rack::Coffee, :root => (@root_dir + "/"), :urls => dirs.map { |d| "/" + d }
  end

  # To have Pixiurge serve static directories of Javascript or assets, call this with the appropriate list of directory names.
  # All directory names are relative to the web root you passed to Pixiurge.root_dir.
  #
  # @param dirs [String, Array<String>] The directory name or array of directory names, located under the web root you passed to Pixiurge.root_dir
  # @since 0.1.0
  def self.static_dirs *dirs
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
  def self.static_files *files
    @static_files ||= []
    @static_files.concat [*files].flatten
  end

  # Get the final, built Rack handler from Pixiurge with all the specified middleware and websocket handling.
  #
  # @see Pixiurge.root_dir
  # @see Pixiurge.static_dirs
  # @see Pixiurge.coffeescript_dirs
  # @since 0.1.0
  def self.handler
    @static_files ||= []
    static_files = @static_files.map { |f| "/" + f }
    lambda do |env|
      if Faye::WebSocket.websocket? env
        @app.websocket_handler env
      else
        if static_files.include?(env["PATH_INFO"])
          file = env["PATH_INFO"]
          path = File.join(@root_dir, file)
          return [200, {'Content-Type' => 'text/html'}, [File.read(path)]]
        else
          return [404, {}, [""]]
        end
      end
    end
  end
end
