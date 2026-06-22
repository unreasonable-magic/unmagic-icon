module Unmagic
  class Icon
    class Library
      class Source
        class BootstrapIcons < Source
          key :"bootstrap-icons"
          title "Bootstrap Icons"
          description "Official open source SVG icon library for Bootstrap"
          url "https://github.com/twbs/icons/archive/refs/tags/v1.13.1.zip"
          archive :zip
          dir "bootstrap-icons"
          extract "icons-1.13.1/icons/*.svg"
        end
      end
    end
  end
end
