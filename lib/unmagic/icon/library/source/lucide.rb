# frozen_string_literal: true

module Unmagic
  class Icon
    class Library
      class Source
        class Lucide < Source
          key :lucide
          title "Lucide Icons"
          description "Beautiful & consistent icons"
          url "https://github.com/lucide-icons/lucide/releases/download/1.21.0/lucide-icons-1.21.0.zip"
          archive :zip
          extract "icons/*.svg"
        end
      end
    end
  end
end
