module Unmagic
  class Icon
    class Library
      class Source
        # Six weights live under assets/<weight>; every non-regular filename
        # already carries its weight suffix (ghost-bold, ghost-fill, …), so we
        # flatten all weights into one library without name collisions. Regular
        # is the bare name (ghost), the rest are ghost-<weight>.
        class Phosphor < Source
          key :phosphor
          title "Phosphor Icons"
          description "Flexible icon family with six weights (thin to fill, plus duotone)"
          url "https://github.com/phosphor-icons/core/archive/refs/tags/v2.0.8.zip"
          archive :zip
          dir "phosphor"
          extract "core-2.0.8/assets/*/*.svg"
        end
      end
    end
  end
end
