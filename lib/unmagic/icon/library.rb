# frozen_string_literal: true

require "json"

module Unmagic
  class Icon
    class Library
      # The optional per-set manifest. Asset-kind-agnostic: it carries metadata,
      # a `default`, a global `aliases` map, and optional per-entry declarations
      # (`entries`, each with its own `aliases`). Icons auto-discover from disk,
      # so for an icon library only `default` + `aliases` are typically present.
      MANIFEST_FILENAME = "manifest.json"

      # The lone asset-kind-specific bit: which files in the directory are assets.
      # SVG today; a future raster pack would scan png/gif here.
      ASSET_GLOB = "*.svg"

      attr_reader :name, :path

      def initialize(name:, path:)
        @name = name
        @path = path
      end

      # Resolve a query to an icon. Order: exact icon file, then the alias index
      # (exact alias, then longest matching glob/pattern), then the manifest's
      # default. Raises when nothing matches and no default is declared.
      def find(query)
        resolve(query.to_s) or
          raise Unmagic::Icon::IconNotFoundError.new("Can't find #{query} in #{path}")
      end

      def icons
        icons_by_key.values
      end

      def aliases
        alias_index
      end

      private

      def resolve(query)
        icons_by_key[query] ||
          aliased(query) ||
          default_icon
      end

      def aliased(query)
        target = lookup_alias(query.downcase)
        icons_by_key[target] if target
      end

      # Exact aliases win over patterns; patterns are tried longest-first so the
      # most specific match wins (e.g. "*.test.tsx" beats "*.tsx").
      def lookup_alias(key)
        exact, patterns = alias_index
        exact[key] ||
          patterns.find { |pattern, _| File.fnmatch?(pattern, key, File::FNM_EXTGLOB) }&.last
      end

      def default_icon
        target = manifest["default"]
        icons_by_key[target] if target
      end

      def icons_by_key
        @icons_by_key ||= Dir.glob(File.join(@path, ASSET_GLOB)).to_h do |icon_path|
          icon_key = File.basename(icon_path, ".svg")
          [ icon_key, Unmagic::Icon.new(name: "#{@name}/#{icon_key}", path: icon_path) ]
        end
      end

      # The whole alias map, normalized to downcased keys and split into exact
      # strings vs glob patterns. Built from the manifest's global `aliases` plus
      # each entry's per-entry `aliases` (the emoji-shaped shortcuts case).
      def alias_index
        @alias_index ||=
          begin
            exact = {}
            patterns = {}

            manifest_aliases.each do |key, target|
              normalized = key.to_s.downcase
              if normalized.match?(/[*?\[{]/)
                patterns[normalized] = target
              else
                exact[normalized] = target
              end
            end

            [ exact, patterns.sort_by { |pattern, _| -pattern.length }.to_h ]
          end
      end

      def manifest_aliases
        global = manifest["aliases"] || {}
        per_entry = Array(manifest["entries"]).each_with_object({}) do |entry, mapped|
          Array(entry["aliases"]).each { |key| mapped[key] = entry["name"] }
        end
        global.merge(per_entry)
      end

      def manifest
        @manifest ||= load_manifest
      end

      def load_manifest
        file = File.join(@path, MANIFEST_FILENAME)
        File.exist?(file) ? JSON.parse(File.read(file)) : {}
      end
    end
  end
end
