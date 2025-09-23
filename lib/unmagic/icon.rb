# frozen_string_literal: true

require_relative "icon/version"
require_relative "icon/configuration"
require_relative "icon/library"
require_relative "icon/library/registry"
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

      def configuration
        @configuration ||= Unmagic::Icon::Configuration.new
      end

      def libraries
        Unmagic::Icon::Library::Registry.all
      end

      def find(reference)
        *library_parts, icon_name = reference.split("/")
        library_path = library_parts.join("/")

        Unmagic::Icon::Library::Registry.find(library_path).find(icon_name)
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

    def to_svg(options = {})
      # Return cached version if it doesn't have any special options
      if options.empty? && @svg_cache
        return @svg_cache
      end

      svg = raw_svg_content.dup

      # Extract or build CSS classes
      css_classes = [
        "unmagic-icon[#{@name}]",
        options[:class]
      ].compact.join(" ")

      # Add attributes to the opening svg tag
      svg.sub!(/<svg\s*/i, "<svg ")
      svg.sub!(/<svg(\s+[^>]*)?>/) do |_match|
        attributes = ::Regexp.last_match(1) || ""

        # Remove any existing class attribute
        attributes.gsub!(/\sclass=["'][^"']*["']/, "")

        # Build new attributes
        new_attributes = []
        new_attributes << %(class="#{css_classes}") if css_classes.present?
        new_attributes << %(role="img")
        new_attributes << %(aria-label="#{@name.humanize}")

        "<svg#{attributes} #{new_attributes.join(' ')}>"
      end

      # Only cache it if it's not got any special options
      if options.empty?
        @svg_cache = @svg
      end

      svg.html_safe
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
