# frozen_string_literal: true

require "pathname"

module Unmagic
  class Icon
    class Configuration
      attr_accessor :paths
      attr_writer :download_path

      def initialize
        @paths = []
      end

      # Where `Unmagic::Icon::Library::Source` writes libraries by default.
      # vendor/icons keeps downloaded sets out of the asset pipeline (Propshaft
      # fingerprints app/assets/*, but the icons are inlined via File.read, never
      # served), and reads as vendored third-party. Must be set explicitly when
      # not running under Rails.
      def download_path
        @download_path ||= default_download_path
      end

      private

      def default_download_path
        return unless defined?(Rails) && Rails.respond_to?(:root) && Rails.root

        Rails.root.join("vendor", "icons")
      end
    end
  end
end
