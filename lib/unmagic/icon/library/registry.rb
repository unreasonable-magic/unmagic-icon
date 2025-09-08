# frozen_string_literal: true

module Unmagic
  class Icon
    class Library
      class Registry
        class << self
          def all
            _all.values
          end

          def exists?(name)
            !_all[name].nil?
          end

          def find(name)
            return name if name.is_a?(Unmagic::Icon::Library)

            _all[name] or
              raise Unmagic::Icon::LibraryNotFoundError.new("Can't find library #{name.inspect}")
          end

          def reset!
            @_all = nil
          end

          private

          def _all
            @_all ||= find_libraries
          end

          def find_libraries
            libs = {}
            Unmagic::Icon.configuration.paths.each do |path|
              build_libraries(path: path).each do |lib|
                libs[lib.name] = lib
              end
            end
            libs
          end

          def build_libraries(path:)
            discovered = []

            # If the path has a `blah:` at the start, extract it and use it as a
            # prefix for the library name
            prefix, path = path.to_s.split(":", 2)
            if path.blank?
              path = prefix
              prefix = nil
            end

            Dir.glob(File.join(path, "**/")).each do |dir_path|
              next unless File.directory?(dir_path)

              # Check if this directory has any SVG files
              svg_files = Dir.glob(File.join(dir_path, "*.svg"))
              next if svg_files.empty?

              # Build library name from path relative to icons root
              library_path = Pathname.new(dir_path)
              relative = library_path.relative_path_from(path).to_s.chomp("/")

              # Skip empty library names (root directory)
              next if relative.empty? || relative == "."

              # Add name prefix if we had one
              name = prefix ? "#{prefix}:#{relative}" : relative

              # Add it to our list
              discovered << Unmagic::Icon::Library.new(name: name, path: library_path)
            end

            discovered
          end
        end
      end
    end
  end
end
