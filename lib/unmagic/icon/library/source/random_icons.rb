# frozen_string_literal: true

module Unmagic
  class Icon
    class Library
      class Source
        class RandomIcons < Source
          key :"random-icons"
          title "Random Icons"
          description "Keith Pitt's collection of SVG icons missing from other packs"
          url "https://codeload.github.com/keithpitt/random-icons/tar.gz/refs/heads/main"
          archive :tgz
          extract "random-icons-main/icons/*.svg"
          notices "random-icons-main/README.md", "random-icons-main/ATTRIBUTION.md"
          provenance "provider" => "keithpitt/random-icons", "revision" => "main",
            "license" => "Per-asset terms; see ATTRIBUTION.md and licenses/",
            "homepage" => "https://github.com/keithpitt/random-icons"

          private

          def copy_assets(tmpdir, target_dir)
            super
            licenses = File.join(tmpdir, "random-icons-main", "licenses")
            FileUtils.cp_r(licenses, target_dir) if File.directory?(licenses)
            sources = File.join(tmpdir, "random-icons-main", "sources.json")
            FileUtils.cp(sources, target_dir) if File.file?(sources)
          end
        end
      end
    end
  end
end
