# frozen_string_literal: true

module Unmagic
  class Icon
    class Library
      class Source
        class Tabler < Source
          key :tabler
          title "Tabler Icons"
          description "Free SVG icons in outline and filled styles"
          url "https://registry.npmjs.org/@tabler/icons/-/icons-3.48.0.tgz"
          archive :tgz
          # Keep outline names at tabler/<name>; filled icons live separately
          # because both styles share filenames.
          extract_into(
            "package/icons/outline" => ".",
            "package/icons/filled" => "filled"
          )
        end
      end
    end
  end
end
