# frozen_string_literal: true

require "cgi"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/string/output_safety"
require "active_support/core_ext/string/inflections"

require_relative "icon/version"
require_relative "icon/configuration"
require_relative "icon/library"
require_relative "icon/library/registry"
require_relative "icon/action_view_helpers"
require_relative "icon/engine" if defined?(Rails)

module Unmagic
  class Icon
    class Error < StandardError; end
    class LibraryNotFoundError < Error; end
    class IconNotFoundError < Error; end

    class << self
      def init
        yield(configuration) if block_given?
        @initialized = true
      end

      def initialized?
        @initialized == true
      end

      def configure
        yield(configuration) if block_given?
        configuration
      end

      def configuration
        @configuration ||= Unmagic::Icon::Configuration.new
      end

      def libraries
        Unmagic::Icon::Library::Registry.all
      end

      def find(reference)
        library_path, icon_name = parse_reference(reference)

        Unmagic::Icon::Library::Registry.find(library_path).find(icon_name)
      end

      # Parse a "library/name" reference into [library, name], tolerating the
      # emoji-style ":library/name:" decoration so both kinds share one syntax.
      def parse_reference(reference)
        *library_parts, name = reference.to_s.gsub(/\A:|:\z/, "").split("/")
        [ library_parts.join("/"), name ]
      end
    end

    attr_reader :name, :path

    def initialize(name:, path:)
      @name = name
      @path = path
    end

    def doc
      Nokogiri::XML(raw_svg_content)
    end

    def attributes
      extracted_svg[:attributes]
    end

    def contents
      extracted_svg[:contents].strip
    end

    def as_json
      { name: name, svg: to_svg }
    end

    # Render the asset to HTML, dispatching on its kind. SVG inlines today; a
    # future raster asset (png/gif) would emit an <img> here, so callers stay
    # render-agnostic.
    def render(options = {})
      case File.extname(@path).downcase
      when ".svg" then to_svg(options)
      else
        raise Unmagic::Icon::Error, "Don't know how to render #{@path}"
      end
    end

    # Render the SVG with a `unmagic-icon` class (plus any caller class) and a
    # `data-unmagic-icon` marker. Any other options are merged verbatim as
    # attributes on the <svg> — so the caller controls accessibility
    # (`aria-hidden`, `aria-label`, `role`), `id`, `data-*`, etc.
    def to_svg(options = {})
      return @svg_cache if options.empty? && @svg_cache

      attributes = options.transform_keys(&:to_s)
      css_classes = [ "unmagic-icon", attributes.delete("class") ].compact.join(" ")

      svg = raw_svg_content.dup
      svg.sub!(/<svg(\s+[^>]*)?>/i) do
        existing = (::Regexp.last_match(1) || "").gsub(/\sclass=["'][^"']*["']/, "")
        extra = attributes.map { |name, value| %(#{name}="#{CGI.escapeHTML(value.to_s)}") }
        %(<svg#{existing} class="#{css_classes}" data-unmagic-icon="#{@name}"#{extra.empty? ? "" : " #{extra.join(' ')}"}>)
      end

      svg = svg.html_safe
      @svg_cache = svg if options.empty?
      svg
    end

    private

    def raw_svg_content
      @raw_svg_content ||= File.read(@path)
    end

    def extracted_svg
      @xml ||=
        begin
          root = doc.at_css("//svg")
          {
            attributes: root.attributes.inject({}) do |hash, (key, value)|
              hash[key] = value.value
              hash
            end,
            contents: root.children.to_xml
          }
        end
    end
  end
end
