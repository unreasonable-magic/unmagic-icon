# frozen_string_literal: true

module Unmagic
  class Icon
    class Library
      attr_reader :name, :path

      def initialize(name:, path:)
        @name = name
        @path = path
      end

      def find(icon_name)
        icons_by_key[icon_name] or
          raise Unmagic::Icon::IconNotFoundError.new("Can't find #{icon_name} in #{path}")
      end

      def icons
        icons_by_key.values
      end

      private

      def icons_by_key
        @icons ||= Dir.glob(File.join(@path, "*.svg")).map do |icon_path|
          icon_key = File.basename(icon_path, ".svg")
          icon_name = "#{@name}/#{icon_key}"
          [ icon_key, Unmagic::Icon.new(name: icon_name, path: icon_path) ]
        end.to_h
      end
    end
  end
end
