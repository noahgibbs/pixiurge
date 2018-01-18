require "thor"
$LOAD_PATH.unshift File.expand_path(File.join(__dir__, "..", ".."))
require "pixiurge"

module Pixiurge
  module Commands
    class Generator < Thor::Group
      include Thor::Actions

      argument :name
      argument :pixiurge_dev

      def self.source_root
        File.join __dir__, "..", "..", "..", "generator"
      end

      #desc "new GAMENAME", "Creates a new Pixiurge game (or similar application)"
      def top_level_directory
        directory "%name%", :mode => :preserve
        chmod(name + "/exe/start_server", 0755)
      end
    end
  end
end
