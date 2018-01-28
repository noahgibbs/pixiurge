require "thor"
$LOAD_PATH.unshift File.expand_path(File.join(__dir__, "..", ".."))
require "pixiurge"

module Pixiurge
  module Commands
    class Generator < Thor::Group
      include Thor::Actions

      argument :name

      def human_name
        @human_name ||= snakecase_name.split("_").map(&:capitalize).join(" ")
      end

      def camelcase_name
        @camel_name ||= snakecase_name.split("_").map(&:capitalize).join
      end

      def snakecase_name
        @snake_name ||= name.gsub(" ", "_").gsub(/([a-z])([A-Z])/, "$1_$2")
      end

      def self.source_root
        File.join __dir__, "..", "..", "..", "generator"
      end

      #desc "new GAMENAME", "Creates a new Pixiurge game or application"
      def top_level_directory
        directory "%snakecase_name%", :mode => :preserve
        chmod(snakecase_name + "/exe/start_server", 0755)
      end
    end
  end
end
