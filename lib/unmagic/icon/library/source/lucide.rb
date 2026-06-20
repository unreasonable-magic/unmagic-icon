# frozen_string_literal: true

module Unmagic
  class Icon
    class Library
      class Source
        class Lucide < Source
          key :lucide
          title "Lucide Icons"
          description "Beautiful & consistent icons"
          url "https://github.com/lucide-icons/lucide/releases/download/v0.468.0/lucide-icons-0.468.0.zip"
          archive :zip
          extract "*.svg"
        end
      end
    end
  end
end
