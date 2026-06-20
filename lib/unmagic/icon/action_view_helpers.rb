# frozen_string_literal: true

module Unmagic
  class Icon
    # View helper, registered into ActionView by the engine. Mirrors the shape a
    # future emoji pack would use (`unmagic_emoji`), so both share one rendering
    # surface.
    module ActionViewHelpers
      def unmagic_icon(reference, **options)
        Unmagic::Icon.find(reference).render(**options)
      end
    end
  end
end
