# frozen_string_literal: true

module Unmagic
  class Icon
    class Library
      class Source
        class DashboardIcons < Source
          REVISION = "c716eb6798576923fa08e9b3e4125173148994ed"
          ROOT = "dashboard-icons-#{REVISION}"

          key :"dashboard-icons"
          title "Dashboard Icons"
          description "Dashboard service logos from Homarr Labs, including light/dark variants"
          url "https://codeload.github.com/homarr-labs/dashboard-icons/tar.gz/#{REVISION}"
          archive :tgz
          # Suffixes such as dagster-light and dagster-dark are part of the name.
          extract "#{ROOT}/svg/*.svg"
          notices "#{ROOT}/LICENSE", "#{ROOT}/README.md"
          provenance "provider" => "homarr-labs/dashboard-icons", "revision" => REVISION, "license" => "Apache-2.0",
            "homepage" => "https://github.com/homarr-labs/dashboard-icons"
        end
      end
    end
  end
end
