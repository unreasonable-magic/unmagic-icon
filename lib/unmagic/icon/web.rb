# frozen_string_literal: true

require "rack"
require "erb"
require "cgi"

module Unmagic
  class Icon
    class Web
      def self.call(env)
        @request = Rack::Request.new(env)

        # Get all libraries
        @libraries = Unmagic::Icon::Library::Registry.all

        # Parse library from path (e.g., /pixelarticons or /fa/sharp/solid)
        path = @request.path_info.sub(%r{^/}, "").sub(%r{/$}, "")

        if path.empty?
          # Redirect to first library
          first_library = @libraries.first.name.to_param
          if first_library.nil?
            return [ 404, { "content-type" => "text/plain" }, [ "No libraries found" ] ]
          else
            query_string = @request.query_string.empty? ? "" : "?#{@request.query_string}"
            return [ 302, { "location" => "#{@request.env["SCRIPT_NAME"]}/#{first_library}#{query_string}" }, [] ]
          end
        end

        begin
          @selected_library = Unmagic::Icon::Library::Registry.find(path)
        rescue Unmagic::Icon::LibraryNotError
          return [ 404, { "content-type" => "text/plain" }, [ "Library not found: #{@selected_library}" ] ]
        end

        @search_query = @request.params["q"] || ""

        # Render the view
        template_path = File.expand_path("web/views/layout.html.erb", __dir__)
        template = ERB.new(File.read(template_path))
        html = template.result(binding)

        [ 200, { "content-type" => "text/html; charset=utf-8" }, [ html ] ]
      end
    end
  end
end
