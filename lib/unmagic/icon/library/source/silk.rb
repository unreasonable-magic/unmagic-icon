# frozen_string_literal: true

module Unmagic
  class Icon
    class Library
      class Source
        # No release archive: fetch the svgs directly from the repo via the
        # GitHub contents API, so #acquire is overridden entirely.
        class Silk < Source
          key :silk
          title "Silk Icons Scalable"
          description "The classic silk icon set recreated as SVG"

          REPO = "frhun/silk-icon-scalable"
          BRANCH = "main"
          PATHS = [ "baseicons", "extra" ].freeze

          private

          def acquire(target_dir)
            FileUtils.mkdir_p(target_dir)

            headers = {
              "Accept" => "application/vnd.github.v3+json",
              "User-Agent" => "unmagic-icon-downloader"
            }

            PATHS.each do |dir_path|
              uri = URI("https://api.github.com/repos/#{REPO}/contents/#{dir_path}?ref=#{BRANCH}")
              response = fetch_with_redirect(uri, headers)
              raise DownloadError, "Failed to list #{dir_path}: HTTP #{response.code}" if response.code != "200"

              files = JSON.parse(response.body).select { |file| file["name"].end_with?(".svg") }
              puts "  Downloading #{files.size} icons from #{dir_path}..."
              each_with_progress(files, show_time: true) do |file|
                download_file(file["download_url"], File.join(target_dir, file["name"]))
              end
            end
          end
        end
      end
    end
  end
end
