# frozen_string_literal: true

require_relative "icon/version"
require_relative "icon/configuration"
require_relative "icon/library"
require_relative "icon/library/registry"
require_relative "icon/web"
require_relative "icon/engine" if defined?(Rails)

module Unmagic
  # Provides a simple interface for managing and rendering SVG icons.
  # Icons are organized into libraries (directories) under app/assets/icons/.
  # Engine icons are automatically discovered from Rails engines.
  #
  # Example:
  #
  #   icon = Unmagic::Icon.find("feather/home")
  #   icon.to_svg(class: "w-5 h-5")
  #   #=> "<svg class='unmagic-icon[feather] fill-current w-5 h-5' role='img' aria-label='Home'>...</svg>"
  #
  #   # Engine icon
  #   icon = Unmagic::Icon.find("unmagic_ui:feather/settings")
  #   icon.to_svg(class: "w-4 h-4")
  #   #=> "<svg class='unmagic-icon[unmagic_ui:feather] fill-current w-4 h-4' role='img' aria-label='Settings'>...</svg>"
  #
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
        @configuration ||= Configuration.new
      end

      def libraries
        Unmagic::Icon::Library::Registry.all
      end

      def find(reference)
        *library_parts, icon_name = reference.split("/")
        library_path = library_parts.join("/")

        Unmagic::Icon::Library::Registry.find(library_path).find(icon_name)
      end

      def search_paths
        @search_paths ||= begin
                            paths = Unmagic::Icon.configuration.paths.dup.map do |path|
                              [ nil, path ]
                            end

                            # Engine icons with prefixes
                            Rails.application.railties.select do |r|
                              r.is_a?(Rails::Engine) && r.class != Rails::Application
                            end.each do |engine|
                              engine_path = engine.root.join("app/assets/icons")
                              next unless engine_path.exist?

                              prefix = engine.class.name.underscore.gsub(%r{/engine$}, "").tr("/", "_")
                              paths << [ prefix, engine_path ]
                            end

                            paths
                          end
      end
    end

    attr_reader :name, :path

    def initialize(name:, path:)
      @name = name
      @path = path
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
        "fill-current",
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
  end
end
