# frozen_string_literal: true

require "digest"

module Unmagic
  class Icon
    class Library
      class Source
        class AwsArchitectureIcons < Source
          SHA256 = "d2d166c453526471749d520e0db022c459abef759d2946cf2dd1d1c992dc6526"
          ATTRIBUTION = <<~TEXT
            AWS Architecture Icons — July 31, 2026
            Icons are the property of Amazon Web Services, Inc. and/or its affiliates.
            Source: https://aws.amazon.com/architecture/icons/
            Terms: https://aws.amazon.com/terms/
            IP license: https://aws.amazon.com/legal/aws-ip-license-terms/

            AWS permits customers and partners to use these assets in architecture
            diagrams and related materials. These are proprietary assets, not assets
            licensed under this gem's MIT license. Downloading does not grant general
            redistribution or trademark rights; check AWS's terms for your use.
            No separate license file is included in this upstream archive.

            This download copies the 64px architecture service SVGs unchanged,
            preserving their upstream filenames. The gem's renderer adds its normal
            SVG wrapper attributes. Other sizes, resource icons and category icons
            are not installed.
          TEXT

          key :"aws-architecture-icons"
          title "AWS Architecture Icons"
          description "Official AWS service icons for architecture diagrams (AWS usage terms apply)"
          url "https://d1.awsstatic.com/onedam/marketing-channels/website/public/shared/architecture-icon-release/Icon-package_07312026.5846e92413caa21490223536cc97f1269e44fa92.zip"
          archive :zip
          extract "Architecture-Service-Icons_07312026/Arch_*/64/*.svg"
          provenance "provider" => "Amazon Web Services", "version" => "2026-07-31",
            "license" => "Proprietary — AWS usage terms", "sha256" => SHA256,
            "homepage" => "https://aws.amazon.com/architecture/icons/",
            "terms" => "https://aws.amazon.com/terms/"

          private

          def download_file(url, destination)
            super
            unless Digest::SHA256.file(destination).hexdigest == SHA256
              raise DownloadError, "AWS Architecture Icons archive checksum mismatch"
            end
          end

          def write_manifest(tmpdir, target_dir)
            super
            File.write(Pathname(target_dir).join("ATTRIBUTION.txt"), ATTRIBUTION)
          end
        end
      end
    end
  end
end
