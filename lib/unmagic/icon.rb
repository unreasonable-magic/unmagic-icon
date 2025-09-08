# frozen_string_literal: true

require_relative "icon/version"
require_relative "icon/configuration"
require_relative "icon/library"
require_relative "icon/scanner"
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
    class MissingLibraryError < Error; end
    class IconNotFoundError < Error; end
    class EngineNotFoundError < Error; end
    class InvalidReferenceError < Error; end

    attr_reader :path, :name, :library_key

    def initialize(path, name, library_key)
      @path = path
      @name = name
      @library_key = library_key
    end

    # Read the SVG content from file
    def svg_content
      @svg_content ||= File.read(@path)
    end

    # Return inline SVG with appropriate attributes
    def to_svg(options = {})
      svg = svg_content.dup

      # Extract or build CSS classes
      css_classes = [
        "unmagic-icon[#{@library_key}]",
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

      svg.html_safe
    end

    class << self
      # Initialize configuration with a block
      def init
        yield(configuration) if block_given?
        @initialized = true
      end

      # Check if initialization has been called
      def initialized?
        @initialized == true
      end

      # Get the current configuration
      def configuration
        @configuration ||= Configuration.new
      end

      def find(reference)
        # Validate reference format
        raise InvalidReferenceError, "Icon reference cannot be blank" if reference.blank?

        # Parse reference: "library/icon" or "engine:library/icon"
        *library_parts, icon_name = reference.split("/")
        library_path = library_parts.join("/")

        # Check for missing icon name
        if icon_name.blank?
          raise MissingLibraryError,
            "Missing library in icon reference: '#{reference}'. Use format: library/icon or engine:library/icon"
        end

        # Check for engine prefix and validate it exists
        if library_path.include?(":")
          engine_prefix = library_path.split(":").first
          available_engines = search_paths.select { |prefix, _| prefix }.map(&:first)

          unless available_engines.include?(engine_prefix)
            available_list = available_engines.any? ? available_engines.join(", ") : "none available"
            raise EngineNotFoundError,
              "Engine '#{engine_prefix}' not found for reference '#{reference}'. Available engines: #{available_list}"
          end
        end

        # Track attempted paths for better error messages
        attempted_paths = []

        # Check each search path
        search_paths.each do |prefix, base_path|
          if library_path.start_with?("#{prefix}:")
            # Engine icon: strip prefix and look in engine path
            relative = library_path.sub("#{prefix}:", "")
            file = base_path.join("#{relative}/#{icon_name}.svg")
            # Library key includes engine prefix: "unmagic_ui:feather"
            library_key = library_path
          elsif prefix.nil?
            # App icon: use path as-is
            file = base_path.join("#{library_path}/#{icon_name}.svg")
            # Library key is just the library name: "feather"
            library_key = library_path
          else
            next
          end

          attempted_paths << file.to_s
          return Icon.new(file, icon_name, library_key) if file.exist?
        end

        # Build helpful error message
        unless library_path.include?(":")
          raise IconNotFoundError,
            "Icon '#{icon_name}' not found in library '#{library_path}' (attempted: #{attempted_paths.join(', ')})"
        end

        engine_prefix, library_name = library_path.split(":", 2)
        raise IconNotFoundError,
          "Icon '#{icon_name}' not found in engine library '#{engine_prefix}:#{library_name}' (attempted: #{attempted_paths.join(', ')})"
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

      attr_reader :libraries

      # Force library discovery at boot time (called from railtie)
      def preload!
        @libraries = Library.discover_all
        total_icons = @libraries.values.sum(&:count)
        puts "[unmagic-icon] Preloaded #{@libraries.count} icon libraries with #{total_icons} total icons"
        @libraries
      end
    end
  end
end
