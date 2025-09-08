# frozen_string_literal: true

module Unmagic
  class Icon
    class Library
      attr_reader :name, :path

      def initialize(name, path)
        @name = name
        @path = path
      end

      # Find an icon in this library
      def find(icon_name)
        icon_path = @path.join("#{icon_name}.svg")
        return nil unless icon_path.exist?

        Unmagic::Icon.new(@name, icon_name, icon_path)
      end

      # List all icons in this library
      def icons
        @icons ||= Dir.glob(@path.join("*.svg")).map do |file|
          File.basename(file, ".svg")
        end
      end

      # Check if library has any SVG files
      def has_icons?
        Dir.glob(@path.join("*.svg")).any?
      end

      class << self
        # Discover all icon libraries with proper prefixes (optimized)
        def discover_all
          @discover_all ||= begin
            libraries = {}

            puts "Looking for icons in #{Icon.search_paths}"

            Icon.search_paths.each do |prefix, base_path|
              # More efficient: walk directories instead of globbing all files
              Dir.glob(File.join(base_path, "**/")).each do |dir_path|
                next unless File.directory?(dir_path)

                # Check if this directory has any SVG files
                svg_files = Dir.glob(File.join(dir_path, "*.svg"))
                next if svg_files.empty?

                # Build library name from path relative to icons root
                library_path = Pathname.new(dir_path)
                relative = library_path.relative_path_from(base_path).to_s.chomp("/")

                # Skip empty library names (root directory)
                next if relative.empty? || relative == "."

                # Add prefix for engine libraries
                library_name = prefix ? "#{prefix}:#{relative}" : relative
                libraries[library_name] = svg_files.map { |f| File.basename(f, ".svg") }
              end
            end

            libraries
          end
        end
      end
    end
  end
end
