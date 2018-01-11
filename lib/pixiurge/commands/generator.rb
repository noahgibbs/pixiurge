require "thor"
$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require "pixiurge/app"

module Pixiurge
  module Commands
    class Generator < Thor::Group
      include Thor::Actions

      argument :name

      def self.source_root
        File.join __dir__, "..", "..", "..", "generator"
      end

      def self.app_name
        name
      end

      #desc "new GAMENAME", "Creates a new Pixiurge game (or similar application)"
      def top_level_directory
        directory "%app_name%"
      end
    end
  end
end
