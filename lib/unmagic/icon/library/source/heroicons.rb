# frozen_string_literal: true

module Unmagic
  class Icon
    class Library
      class Source
        class Heroicons < Source
          key :heroicons
          title "Heroicons"
          description "Beautiful hand-crafted SVG icons by the makers of Tailwind CSS"
          url "https://github.com/tailwindlabs/heroicons/archive/refs/tags/v2.2.0.zip"
          archive :zip
          extract_into(
            "heroicons-2.2.0/optimized/16/solid" => "16-solid",
            "heroicons-2.2.0/optimized/20/solid" => "20-solid",
            "heroicons-2.2.0/optimized/24/solid" => "24-solid",
            "heroicons-2.2.0/optimized/24/outline" => "24-outline"
          )
        end
      end
    end
  end
end
