# frozen_string_literal: true

module Unmagic
  class Icon
    class Library
      class Source
        # PKief's material-icon-theme, sourced from the npm tarball so we also get
        # dist/material-icons.json — the file→icon mapping — which we turn into a
        # manifest.json of aliases.
        class MaterialFileIcons < Source
          key :"material-file-icons"
          title "Material File Icons"
          description "Material Design file icons with filename/extension aliases (PKief material-icon-theme)"
          url "https://registry.npmjs.org/material-icon-theme/-/material-icon-theme-5.35.0.tgz"
          archive :tgz
          dir "material"
          extract "package/icons/*.svg"

          private

          def write_manifest(tmpdir, target_dir)
            json_path = File.join(tmpdir, "package", "dist", "material-icons.json")
            return unless File.exist?(json_path)

            data = JSON.parse(File.read(json_path))
            definitions = data["iconDefinitions"] || {}

            rename_clones(definitions, target_dir)

            aliases = {}
            (data["fileExtensions"] || {}).each { |extension, name| aliases["*.#{extension.downcase}"] = name }
            (data["fileNames"] || {}).each { |filename, name| aliases[filename.downcase] = name }

            manifest = {
              "name" => "material",
              "description" => "Material Design file icons (PKief material-icon-theme)",
              "provider" => "material-icon-theme",
              "default" => data["file"] || "file",
              "aliases" => aliases
            }

            File.write(Pathname(target_dir).join("manifest.json"), JSON.pretty_generate(manifest))
            puts "  ✓ Wrote manifest.json (#{aliases.size} aliases)"
          end

          # Material ships ~72 "*.clone.svg" files; rename them to the clean icon
          # name the aliases point at, so on-disk names match the manifest targets.
          def rename_clones(definitions, target_dir)
            target_dir = Pathname(target_dir)

            definitions.each do |name, info|
              basename = File.basename(info["iconPath"].to_s, ".svg")
              next if basename == name

              source = target_dir.join("#{basename}.svg")
              destination = target_dir.join("#{name}.svg")
              FileUtils.mv(source, destination) if source.exist? && !destination.exist?
            end
          end
        end
      end
    end
  end
end
