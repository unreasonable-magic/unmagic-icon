# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "pathname"
require "fileutils"
require "tmpdir"
require "open3"

# Terminal progress is a nicety, not a requirement. The downloader runs fine
# (with plain output) when these sibling gems aren't installed.
begin
  require "unmagic/terminal/progress_bar"
  require "unmagic/support/monitored_enumerator"
rescue LoadError
  # no-op — falls back to plain iteration in #each_with_progress
end

module Unmagic
  class Icon
    class Library
      # A downloadable source for an icon library: its metadata and how to fetch
      # it. Each library is a subclass that declares metadata with the class-level
      # DSL; the base carries the shared download/extract/manifest plumbing. A
      # subclass overrides #write_manifest to generate a mapping, or #acquire to
      # use a different transport.
      class Source
        class Error < StandardError; end
        class DownloadError < Error; end
        class ExtractionError < Error; end

        REGISTRY = {}

        class << self
          def all
            REGISTRY.values
          end

          def find(name)
            REGISTRY[name.to_sym] or raise ArgumentError, "Unknown library: #{name}"
          end

          def exists?(name)
            REGISTRY.key?(name.to_sym)
          end

          # ---- metadata DSL (each setter doubles as a reader) ----

          def key(value = nil)
            return @key unless value

            @key = value.to_sym
            REGISTRY[@key] = self
          end

          def title(value = nil)
            value ? @title = value : @title
          end

          def description(value = nil)
            value ? @description = value : @description
          end

          def url(value = nil)
            value ? @url = value : @url
          end

          def archive(value = nil)
            value ? @archive = value : @archive
          end

          # On-disk directory name; defaults to the key.
          def dir(value = nil)
            value ? @dir = value.to_s : (@dir || key.to_s)
          end

          # Glob patterns (relative to the extracted archive) of svgs to copy.
          def extract(*patterns)
            patterns.empty? ? (@extract || []) : @extract = patterns
          end

          # Map source directories to target subdirectories (e.g. heroicons sizes).
          def extract_into(mapping = nil)
            mapping ? @extract_into = mapping : @extract_into
          end
        end

        def download(target_dir: default_target_dir, force: false)
          target_dir = Pathname(target_dir)

          if target_dir.exist? && !force
            puts "→ Skipping #{self.class.title} (already exists at #{target_dir}, use force: true to re-download)"
            return
          end

          puts "→ Downloading #{self.class.title}..."
          puts "  #{self.class.description}"

          acquire(target_dir)

          puts "  ✓ Downloaded #{count_svgs(target_dir)} icons to #{target_dir}"
        end

        private

        def default_target_dir
          base = Unmagic::Icon.configuration.download_path
          raise ArgumentError, "Set Unmagic::Icon.configuration.download_path or pass target_dir:" unless base

          Pathname(base).join(self.class.dir)
        end

        # Default acquisition: download an archive, extract, copy matched svgs,
        # then let the subclass write a manifest. Override for other transports.
        def acquire(target_dir)
          Dir.mktmpdir do |tmpdir|
            archive_path = File.join(tmpdir, "#{self.class.key}#{File.extname(self.class.url)}")
            download_file(self.class.url, archive_path)
            extract_archive(archive_path, tmpdir, self.class.archive)

            FileUtils.mkdir_p(target_dir)
            copy_assets(tmpdir, target_dir)
            write_manifest(tmpdir, target_dir)
          end
        end

        # Libraries that ship a file→icon mapping override this to write a
        # manifest.json into target_dir. Default: nothing.
        def write_manifest(_tmpdir, _target_dir)
        end

        def copy_assets(tmpdir, target_dir)
          if self.class.extract_into
            copy_into_subdirs(tmpdir, target_dir)
          else
            copy_flat(tmpdir, target_dir)
          end
        end

        def copy_flat(tmpdir, target_dir)
          files = self.class.extract.flat_map do |pattern|
            Dir.glob(File.join(tmpdir, pattern)).select { |file| File.file?(file) }
          end
          return if files.empty?

          puts "  Extracting #{files.size} icons..."
          each_with_progress(files) { |file| FileUtils.cp(file, target_dir) }
        end

        def copy_into_subdirs(tmpdir, target_dir)
          files = self.class.extract_into.flat_map do |source_dir, subdir|
            Dir.glob(File.join(tmpdir, source_dir, "*.svg")).map { |file| [ file, subdir ] }
          end
          return if files.empty?

          puts "  Extracting #{files.size} icons..."
          each_with_progress(files) do |(file, subdir)|
            next unless File.file?(file)

            destination = Pathname(target_dir).join(subdir)
            FileUtils.mkdir_p(destination)
            FileUtils.cp(file, destination)
          end
        end

        def each_with_progress(items, show_time: false)
          if defined?(Unmagic::Support::MonitoredEnumerator) && defined?(Unmagic::Terminal::ProgressBar)
            bar = Unmagic::Terminal::ProgressBar.new(total: items.size, width: 40, show_time: show_time)
            monitor = proc do |event|
              case event.event
              when :progress
                bar.update(event.progress.current + 1)
                print "\r  #{bar.render}"
              when :finish
                puts
              end
            end

            Unmagic::Support::MonitoredEnumerator.new(items, monitor).each { |item| yield item }
          else
            items.each { |item| yield item }
          end
        end

        def download_file(url, destination)
          response = fetch_with_redirect(URI(url))
          raise DownloadError, "Failed to download #{url}: HTTP #{response.code}" if response.code != "200"

          File.binwrite(destination, response.body)
        end

        def fetch_with_redirect(uri, headers = {}, limit = 10)
          raise DownloadError, "Too many redirects" if limit.zero?

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == "https")

          request = Net::HTTP::Get.new(uri)
          headers.each { |name, value| request[name] = value }

          response = http.request(request)

          case response
          when Net::HTTPSuccess
            response
          when Net::HTTPRedirection
            fetch_with_redirect(URI(response["location"]), headers, limit - 1)
          else
            response
          end
        end

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

        def count_svgs(directory)
          Dir.glob(File.join(directory, "**", "*.svg")).size
        end
      end
    end
  end
end

require_relative "source/heroicons"
require_relative "source/devicons"
require_relative "source/feather"
require_relative "source/tabler"
require_relative "source/lucide"
require_relative "source/simple_icons"
require_relative "source/material_file_icons"
require_relative "source/silk"
require_relative "source/coloured_icons"
require_relative "source/bootstrap_icons"
require_relative "source/octicons"
require_relative "source/iconoir"
require_relative "source/material_design_icons"
require_relative "source/phosphor"
