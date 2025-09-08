# frozen_string_literal: true

require "rack"
require "erb"
require "cgi"

module Unmagic
  class Icon
    class Web
      def self.call(env)
        new.call(env)
      end

      def call(env)
        request = Rack::Request.new(env)

        # Get all libraries
        @libraries = Unmagic::Icon.libraries

        # Parse library from path (e.g., /pixelarticons or /fa/sharp/solid)
        path = request.path_info.sub(%r{^/}, "").sub(%r{/$}, "")

        if path.empty?
          # Redirect to first library
          first_library = @libraries.keys.first
          if first_library.nil?
            return [ 404, { "content-type" => "text/plain" }, [ "No libraries found" ] ]
          else
            query_string = request.query_string.empty? ? "" : "?#{request.query_string}"
            return [ 302, { "location" => "/#{first_library}#{query_string}" }, [] ]
          end
        end

        @selected_library = path
        @search_query = request.params["q"] || ""

        # Check if library exists
        unless @libraries.key?(@selected_library)
          return [ 404, { "content-type" => "text/plain" }, [ "Library not found: #{@selected_library}" ] ]
        end

        # Render the view
        template_path = File.expand_path("web/layout.html.erb", __dir__)
        template = ERB.new(File.read(template_path))
        html = template.result(binding)

        [ 200, { "content-type" => "text/html; charset=utf-8" }, [ html ] ]
      end

      private

      def all_icons_json
        icons_data = {}
        @libraries.each do |library_name, library|
          icons_data[library_name] = library.icons
        end
        icons_data.to_json
      end

      def render_icon_svg(library_name, icon_name)
        # Search through configured paths to find the icon
        icon_path = nil
        search_paths = Unmagic::Icon.search_paths

        search_paths.each do |prefix, base_path|
          next unless prefix.nil?

          # Main path
          potential_path = base_path.join("#{library_name}/#{icon_name}.svg")
          if potential_path.exist?
            icon_path = potential_path
            break
          end
        end

        unless icon_path
          # Debug info
          searched_paths = search_paths.map do |prefix, base_path|
            prefix.nil? ? base_path.join("#{library_name}/#{icon_name}.svg").to_s : "#{prefix}:#{base_path}"
          end
          raise "Icon not found: #{library_name}/#{icon_name}. Searched paths: #{searched_paths.join(', ')}"
        end

        svg = File.read(icon_path)
        # Only add fill="currentColor" if the SVG doesn't already have a fill attribute
        if svg.match?(/<svg[^>]*fill=/m)
          svg
        else
          svg.sub(/<svg/, '<svg fill="currentColor"')
        end
      end
    end
  end
end
