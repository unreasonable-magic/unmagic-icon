# frozen_string_literal: true

module Unmagic
  class Icon
    class Library
      class Source
        class CarbonPictograms < Source
          key :"carbon-pictograms"
          title "IBM Carbon Pictograms"
          description "IBM Carbon pictograms, including the IBM Cloud mark"
          url "https://registry.npmjs.org/@carbon/pictograms/-/pictograms-12.85.0.tgz"
          archive :tgz
          # Use the published SVGs, not src/svg duplicates or JS components.
          extract "package/svg/*.svg"
          notices "package/LICENSE", "package/README.md"
          provenance "provider" => "@carbon/pictograms", "version" => "12.85.0", "license" => "Apache-2.0",
            "homepage" => "https://github.com/carbon-design-system/carbon"
        end
      end
    end
  end
end
