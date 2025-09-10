# frozen_string_literal: true

require "rack"
require "rack/utils"

require "erb"
require "cgi"

module Unmagic
  class Icon
    class Web
      def self.call(env)
        app.call(env)
      end

      def self.app
        @app ||= Rack::Builder.new do
          public_path = File.expand_path("web/public", __dir__)
          use Rack::Static, urls: [ "/public" ], root: File.dirname(public_path)
          run Unmagic::Icon::Web.new
        end.to_app
      end

      def call(env)
        @request = Rack::Request.new(env)
        @libraries = Unmagic::Icon::Library::Registry.all

        case @request.path_info
        when "/"
          # Redirect to first library
          first_library = @libraries.first.name.to_param
          if first_library.nil?
            [ 404, { "content-type" => "text/plain" }, [ "No libraries found" ] ]
          else
            [ 302, { "location" => url(first_library, @request.params) }, [] ]
          end
        else
          library_name = @request.path_info.delete_prefix("/")

          begin
            @selected_library = Unmagic::Icon::Library::Registry.find(library_name)
          rescue Unmagic::Icon::LibraryNotError
            return [ 404, { "content-type" => "text/plain" }, [ "Library not found: #{@selected_library}" ] ]
          end

          template_path = File.expand_path("web/views/layout.html.erb", __dir__)
          template = ERB.new(File.read(template_path))
          html = template.result(binding)

          [ 200, { "content-type" => "text/html; charset=utf-8" }, [ html ] ]
        end
      end

      def escape(text)
        CGI.escapeHTML(text.to_s)
      end

      def url(path_parts, params_hash = nil)
        url = [ @request.env["SCRIPT_NAME"], *path_parts ].compact.join("/")
        url = url.gsub(/\/\//, "/")

        if params_hash
          "#{url}?#{Rack::Utils.build_query(params_hash)}"
        else
          url
        end
      end
    end
  end
end
