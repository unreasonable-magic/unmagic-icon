# frozen_string_literal: true

module Unmagic
  class Icon
    class Library
      class Source
        class SvgLogos < Source
          REVISION = "37a6b807fd71c622efea27a9309b5d4edc792969"
          ROOT = "logos-#{REVISION}"

          key :"svg-logos"
          title "SVG Logos"
          description "Full-colour technology logos curated by Gil Barbara"
          url "https://codeload.github.com/gilbarbara/logos/tar.gz/#{REVISION}"
          archive :tgz
          extract "#{ROOT}/logos/*.svg"
          notices "#{ROOT}/LICENSE.txt", "#{ROOT}/README.md", "#{ROOT}/logos.json"
          provenance "provider" => "gilbarbara/logos", "revision" => REVISION, "license" => "CC0-1.0",
            "homepage" => "https://github.com/gilbarbara/logos"
          # Keep upstream names, including slim (the PHP framework). No language
          # aliases or parent-company fallbacks are inferred from the catalogue.
        end
      end
    end
  end
end
