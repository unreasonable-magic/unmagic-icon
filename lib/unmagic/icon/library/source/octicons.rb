module Unmagic
  class Icon
    class Library
      class Source
        # GitHub's icon set. Names carry their size (e.g. alert-16, alert-24).
        class Octicons < Source
          key :octicons
          title "Octicons"
          description "Icons and icon font from GitHub"
          url "https://registry.npmjs.org/@primer/octicons/-/octicons-19.38.0.tgz"
          archive :tgz
          dir "octicons"
          extract "package/build/svg/*.svg"
        end
      end
    end
  end
end
