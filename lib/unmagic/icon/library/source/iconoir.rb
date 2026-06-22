module Unmagic
  class Icon
    class Library
      class Source
        # Ships regular and solid styles under icons/<style>; keep them as
        # separate sub-libraries (iconoir/regular, iconoir/solid) so the shared
        # icon names don't collide.
        class Iconoir < Source
          key :iconoir
          title "Iconoir"
          description "Free open source icons designed on a 24x24 grid"
          url "https://github.com/iconoir-icons/iconoir/archive/refs/tags/v7.11.1.zip"
          archive :zip
          dir "iconoir"
          extract_into(
            "iconoir-7.11.1/icons/regular" => "regular",
            "iconoir-7.11.1/icons/solid" => "solid"
          )
        end
      end
    end
  end
end
