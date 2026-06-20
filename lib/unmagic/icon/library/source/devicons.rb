# frozen_string_literal: true

module Unmagic
  class Icon
    class Library
      class Source
        class Devicons < Source
          key :devicons
          title "Devicons"
          description "Icons representing programming languages, designing & development tools"
          url "https://github.com/devicons/devicon/archive/refs/tags/v2.17.0.zip"
          archive :zip
          extract "devicon-2.17.0/icons/**/*.svg"
        end
      end
    end
  end
end
