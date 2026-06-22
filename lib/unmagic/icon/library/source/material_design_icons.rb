module Unmagic
  class Icon
    class Library
      class Source
        # Pictogrammers' Material Design Icons (@mdi/svg) — the general-purpose
        # icon set, distinct from the file-type icons in MaterialFileIcons.
        class MaterialDesignIcons < Source
          key :"material-design-icons"
          title "Material Design Icons"
          description "7400+ Material Design icons (Pictogrammers @mdi)"
          url "https://github.com/Templarian/MaterialDesign-SVG/archive/refs/tags/v7.4.47.zip"
          archive :zip
          dir "material-design-icons"
          extract "MaterialDesign-SVG-7.4.47/svg/*.svg"
        end
      end
    end
  end
end
