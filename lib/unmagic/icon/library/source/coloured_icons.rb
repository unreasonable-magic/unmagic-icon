module Unmagic
  class Icon
    class Library
      class Source
        # Coloured Icons: full-colour brand/logo svgs organised by category in
        # the repo (public/logos/<category>/<name>/<name>.svg). No release asset,
        # but GitHub serves a tag archive; we flatten every svg into one library.
        class ColouredIcons < Source
          key :"coloured-icons"
          title "Coloured Icons"
          description "Full-colour brand and technology logos"
          url "https://github.com/dheereshag/coloured-icons/archive/refs/tags/1.9.7.zip"
          archive :zip
          dir "coloured-icons"
          extract "coloured-icons-1.9.7/public/logos/**/*.svg"
        end
      end
    end
  end
end
