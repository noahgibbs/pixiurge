module Pixiurge
  class TemplateView
    # HTML to include JavaScript for the appropriate Pixiurge scripts.
    def pixiurge_scripts
      out_html = ""
      pix_dir = File.join(__dir__, "..", "..", "pixiurge")
      Dir[File.join(pix_dir, "*.js")].sort.each do |js_file|
        filebase = File.basename(js_file)
        next if filebase == "webpack.config.js"
        out_html += "<script src=\"/pixiurge/#{filebase}\"></script>\n"
      end
      vendor_dir = File.join(__dir__, "..", "..", "vendor", "dev")
      Dir[File.join(vendor_dir, "*.js")].sort.each do |js_file|
        filebase = File.basename(js_file)
        out_html += "<script src=\"/vendor/#{filebase}\"></script>\n"
      end
      out_html
    end
  end
end
