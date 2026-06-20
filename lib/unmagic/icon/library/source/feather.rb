# frozen_string_literal: true

module Unmagic
  class Icon
    class Library
      class Source
        class Feather < Source
          key :feather
          title "Feather Icons"
          description "Simply beautiful open source icons"
          url "https://github.com/feathericons/feather/archive/refs/tags/v4.29.1.zip"
          archive :zip
          extract "feather-4.29.1/icons/*.svg"
        end
      end
    end
  end
end
