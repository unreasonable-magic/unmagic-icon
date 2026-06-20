# frozen_string_literal: true

module Unmagic
  class Icon
    class Library
      class Source
        class SimpleIcons < Source
          key :"simple-icons"
          title "Simple Icons"
          description "SVG icons for popular brands"
          url "https://registry.npmjs.org/simple-icons/-/simple-icons-14.2.0.tgz"
          archive :tgz
          extract "package/icons/*.svg"
        end
      end
    end
  end
end
