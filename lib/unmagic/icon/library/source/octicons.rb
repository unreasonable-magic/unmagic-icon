module Unmagic
  class Icon
    class Library
      class Source
        # GitHub's icon set. Names carry their size (e.g. alert-16, alert-24).
        class Octicons < Source
          key :octicons
          title "Octicons"
          description "Icons and icon font from GitHub"
          url "https://github.com/primer/octicons/archive/refs/tags/v19.28.1.zip"
          archive :zip
          dir "octicons"
          extract "octicons-19.28.1/icons/*.svg"
        end
      end
    end
  end
end
