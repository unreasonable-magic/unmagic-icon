# frozen_string_literal: true

require "net/http"
require "uri"
require "fileutils"
require "tmpdir"
require "open3"
require "unmagic/terminal/progress_bar"
require "unmagic/support/monitored_enumerator"

module Unmagic
  class Icon
    class Library
      class Downloader
        class Error < StandardError; end
        class DownloadError < Error; end
        class ExtractionError < Error; end

        # Configuration for each icon library
        LIBRARIES = {
          heroicons: {
            name: "Heroicons",
            description: "Beautiful hand-crafted SVG icons by the makers of Tailwind CSS",
            url: "https://github.com/tailwindlabs/heroicons/archive/refs/tags/v2.2.0.zip",
            type: :zip,
            extract_paths: [
              "heroicons-2.2.0/optimized/16/solid/*.svg",
              "heroicons-2.2.0/optimized/20/solid/*.svg",
              "heroicons-2.2.0/optimized/24/solid/*.svg",
              "heroicons-2.2.0/optimized/24/outline/*.svg"
            ],
            target_subdirs: {
              "heroicons-2.2.0/optimized/16/solid" => "16-solid",
              "heroicons-2.2.0/optimized/20/solid" => "20-solid",
              "heroicons-2.2.0/optimized/24/solid" => "24-solid",
              "heroicons-2.2.0/optimized/24/outline" => "24-outline"
            }
          },
          feather: {
            name: "Feather Icons",
            description: "Simply beautiful open source icons",
            url: "https://github.com/feathericons/feather/archive/refs/tags/v4.29.1.zip",
            type: :zip,
            extract_paths: [ "feather-4.29.1/icons/*.svg" ]
          },
          tabler: {
            name: "Tabler Icons",
            description: "Over 5400 free SVG icons",
            url: "https://github.com/tabler/tabler-icons/releases/download/v3.24.0/tabler-icons-3.24.0.zip",
            type: :zip,
            extract_paths: [ "svg/*.svg" ]
          },
          lucide: {
            name: "Lucide Icons",
            description: "Beautiful & consistent icons",
            url: "https://github.com/lucide-icons/lucide/releases/download/v0.468.0/lucide-icons-0.468.0.zip",
            type: :zip,
            extract_paths: [ "*.svg" ]
          },
          "simple-icons": {
            name: "Simple Icons",
            description: "SVG icons for popular brands",
            url: "https://registry.npmjs.org/simple-icons/-/simple-icons-14.2.0.tgz",
            type: :tgz,
            extract_paths: [ "package/icons/*.svg" ]
          },
          silk: {
            name: "Silk Icons Scalable",
            description: "The classic silk icon set recreated as SVG",
            type: :github_raw,
            repo: "frhun/silk-icon-scalable",
            branch: "main",
            paths: [
              "baseicons/*.svg",
              "extra/*.svg"
            ]
          }
        }.freeze

        attr_reader :library

        def initialize(library:)
          library = library.to_sym
          raise ArgumentError, "Unknown library: #{library}" unless LIBRARIES[library.to_sym]
          @library = library
        end

        # Download a specific icon library
        def download(target_dir: Rails.root.join("app/assets/icons/#{library}"), force: false)
          config = LIBRARIES[library]

          if Dir.exist?(target_dir) && !force
            puts "→ Skipping #{config[:name]} (already exists at #{target_dir}, use force: true to re-download)"
            return
          end

          puts "→ Downloading #{config[:name]}..."
          puts "  #{config[:description]}"

          case config[:type]
          when :github_raw
            download_github_raw(library, config, target_dir)
          else
            download_archive(library, config, target_dir)
          end

          count = count_svgs(target_dir)
          puts "  ✓ Downloaded #{count} icons to #{target_dir}"
        end

        private

        # Download and extract archive files (zip, tgz)
        def download_archive(library, config, target_dir)
          Dir.mktmpdir do |tmpdir|
            # Download file
            archive_path = File.join(tmpdir, "#{library}#{File.extname(config[:url])}")
            download_file(config[:url], archive_path)

            # Extract archive
            extract_archive(archive_path, tmpdir, config[:type])

            # Create target directory
            FileUtils.mkdir_p(target_dir)

            # Move SVG files to target
            all_files = []
            if config[:target_subdirs]
              # Handle multiple subdirectories (like heroicons)
              config[:target_subdirs].each do |source_pattern, target_subdir|
                full_pattern = File.join(tmpdir, source_pattern, "*.svg")
                files = Dir.glob(full_pattern)
                all_files.concat(files.map { |f| [ f, target_subdir ] })
              end

              if all_files.any?
                puts "  Extracting #{all_files.size} icons..."
                progress_bar = Unmagic::Terminal::ProgressBar.new(
                  total: all_files.size,
                  width: 40,
                  show_time: false
                )

                monitor = proc do |event|
                  case event.event
                  when :progress
                    progress_bar.update(event.progress.current + 1)
                    print "\r  #{progress_bar.render}"
                  when :finish
                    puts # New line after progress
                  end
                end

                monitored = Unmagic::Support::MonitoredEnumerator.new(all_files, monitor)
                monitored.each do |(svg_file, target_subdir)|
                  target_subdir_path = target_dir.join(target_subdir)
                  FileUtils.mkdir_p(target_subdir_path)
                  FileUtils.cp(svg_file, target_subdir_path) if File.file?(svg_file)
                end
              end
            else
              # Simple extraction - collect all files first
              config[:extract_paths].each do |pattern|
                files = Dir.glob(File.join(tmpdir, pattern))
                all_files.concat(files.select { |f| File.file?(f) })
              end

              if all_files.any?
                puts "  Extracting #{all_files.size} icons..."
                progress_bar = Unmagic::Terminal::ProgressBar.new(
                  total: all_files.size,
                  width: 40,
                  show_time: false
                )

                monitor = proc do |event|
                  case event.event
                  when :progress
                    progress_bar.update(event.progress.current + 1)
                    print "\r  #{progress_bar.render}"
                  when :finish
                    puts # New line after progress
                  end
                end

                monitored = Unmagic::Support::MonitoredEnumerator.new(all_files, monitor)
                monitored.each do |svg_file|
                  FileUtils.cp(svg_file, target_dir)
                end
              end
            end
          end
        end

        # Download raw files from GitHub repository
        def download_github_raw(_library, config, target_dir)
          FileUtils.mkdir_p(target_dir)

          base_url = "https://api.github.com/repos/#{config[:repo]}/contents"
          headers = {
            "Accept" => "application/vnd.github.v3+json",
            "User-Agent" => "unmagic-icon-downloader"
          }

          config[:paths].each do |path_pattern|
            dir_path = path_pattern.split("*.svg").first

            # Get directory listing from GitHub API
            uri = URI("#{base_url}/#{dir_path}?ref=#{config[:branch] || 'main'}")
            response = fetch_with_redirect(uri, headers)

            raise DownloadError, "Failed to list #{dir_path}: HTTP #{response.code}" if response.code != "200"

            files = JSON.parse(response.body)
            svg_files = files.select { |f| f["name"].end_with?(".svg") }

            puts "  Downloading #{svg_files.size} icons from #{dir_path}..."

            # Create progress bar for this path
            progress_bar = Unmagic::Terminal::ProgressBar.new(
              total: svg_files.size,
              width: 40,
              show_time: true
            )

            monitor = proc do |event|
              case event.event
              when :progress
                progress_bar.update(event.progress.current + 1)
                print "\r  #{progress_bar.render}"
              when :finish
                puts # New line after progress
              end
            end

            monitored = Unmagic::Support::MonitoredEnumerator.new(svg_files, monitor)
            monitored.each do |file|
              download_file(file["download_url"], File.join(target_dir, file["name"]))
            end
          end
        end

        # Download a file from URL to destination
        def download_file(url, destination)
          uri = URI(url)
          response = fetch_with_redirect(uri)

          raise DownloadError, "Failed to download #{url}: HTTP #{response.code}" if response.code != "200"

          File.binwrite(destination, response.body)
        end

        # Fetch with redirect support
        def fetch_with_redirect(uri, headers = {}, limit = 10)
          raise DownloadError, "Too many redirects" if limit.zero?

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == "https")

          request = Net::HTTP::Get.new(uri)
          headers.each { |k, v| request[k] = v }

          response = http.request(request)

          case response
          when Net::HTTPSuccess
            response
          when Net::HTTPRedirection
            location = response["location"]
            new_uri = URI(location)
            fetch_with_redirect(new_uri, headers, limit - 1)
          else
            response
          end
        end

        # Extract archive based on type
        def extract_archive(archive_path, destination, type)
          case type
          when :zip
            _, stderr, status = Open3.capture3("unzip", "-q", "-o", archive_path, "-d", destination)
            raise ExtractionError, "Failed to extract zip: #{stderr}" unless status.success?
          when :tgz, :tar
            _, stderr, status = Open3.capture3("tar", "-xzf", archive_path, "-C", destination)
            raise ExtractionError, "Failed to extract tar: #{stderr}" unless status.success?
          else
            raise ExtractionError, "Unknown archive type: #{type}"
          end
        end

        # Count SVG files in directory
        def count_svgs(directory)
          Dir.glob(File.join("**/*.svg")).size
        end
      end
    end
  end
end
