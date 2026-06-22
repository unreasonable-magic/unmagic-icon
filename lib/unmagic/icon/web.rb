# frozen_string_literal: true

require "rack"
require "rack/utils"

require "erb"
require "cgi"
require "json"

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

      # The library param value that means "show icons from every library".
      ALL_LIBRARIES = "all"

      # How many icons to send per page (initial render and each "load more").
      PAGE_SIZE = 100

      def call(env)
        @request = Rack::Request.new(env)
        @libraries = Unmagic::Icon::Library::Registry.all

        @search_query = @request.params["search"].to_s
        @offset = @request.params["offset"].to_i
        @offset = 0 if @offset.negative?
        library_param = @request.params["library"].to_s

        # No `library` param (a fresh page load) defaults to "All".
        if library_param.empty? || library_param == ALL_LIBRARIES
          @selected_library = nil
          @selected_param = ALL_LIBRARIES
          candidates = @libraries.flat_map(&:icons)
        else
          begin
            @selected_library = Unmagic::Icon::Library::Registry.find(library_param)
          rescue Unmagic::Icon::LibraryNotFoundError
            return [ 404, { "content-type" => "text/plain" }, [ "Library not found: #{library_param}" ] ]
          end
          @selected_param = @selected_library.name
          candidates = @selected_library.icons
        end

        # Search and paginate on the server; only the page's icons get their svg
        # read+serialized, so we never inline the whole (possibly huge) set.
        filtered = filter_icons(candidates, @search_query)
        @total = filtered.length
        @page_icons = filtered[@offset, PAGE_SIZE] || []

        return fragment_response if fragment_request?

        template_path = File.expand_path("web/views/layout.html.erb", __dir__)
        template = ERB.new(File.read(template_path))
        html = template.result(binding)

        [ 200, { "content-type" => "text/html; charset=utf-8" }, [ html ] ]
      end

      def escape(text)
        CGI.escapeHTML(text.to_s)
      end

      # Case-insensitive substring match on the icon name.
      def filter_icons(icons, query)
        return icons if query.empty?

        needle = query.downcase
        icons.select { |icon| icon.name.downcase.include?(needle) }
      end

      def fragment_request?
        @request.params["format"] == "fragment"
      end

      # The page of icons as a rendered HTML fragment, which the browser appends
      # ("load more") or swaps in (live search). Counts ride along as headers so
      # the body stays pure markup. Icons are rendered in exactly one place —
      # the `icons` partial, shared with the full page.
      def fragment_response
        headers = {
          "content-type" => "text/html; charset=utf-8",
          "x-total-count" => @total.to_s,
          "x-offset" => @offset.to_s,
          "x-page-size" => PAGE_SIZE.to_s
        }

        [ 200, headers, [ render_icons(@page_icons) ] ]
      end

      # Render the shared icons partial for a list of icons. `-%>` trim keeps the
      # output empty (not whitespace) when there are no icons, so the browser can
      # detect "no results".
      def render_icons(icons)
        template_path = File.expand_path("web/views/icons.html.erb", __dir__)
        ERB.new(File.read(template_path), trim_mode: "-").result(binding)
      end

      # Build a URL to the gallery selecting the given library, carrying the
      # current search query along. `library_name` of nil selects "All".
      def library_url(library_name)
        params = { "library" => library_name || ALL_LIBRARIES }
        params["search"] = @search_query unless @search_query.empty?
        url(params)
      end

      # Build a static asset URL, honouring any SCRIPT_NAME mount prefix.
      def asset_url(path)
        [ @request.env["SCRIPT_NAME"], path ].join.gsub(%r{/+}, "/")
      end

      private

      def url(params)
        base = @request.env["SCRIPT_NAME"].to_s
        base = "/" if base.empty?
        "#{base}?#{Rack::Utils.build_query(params)}"
      end
    end
  end
end
