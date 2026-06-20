# frozen_string_literal: true

module Unmagic
  class Icon
    class Library
      class Source
        class Tabler < Source
          key :tabler
          title "Tabler Icons"
          description "Over 5400 free SVG icons"
          url "https://github.com/tabler/tabler-icons/releases/download/v3.24.0/tabler-icons-3.24.0.zip"
          archive :zip
          extract "svg/*.svg"
        end
      end
    end
  end
end
