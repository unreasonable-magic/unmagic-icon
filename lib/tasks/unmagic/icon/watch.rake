# frozen_string_literal: true

namespace :unmagic do
  namespace :icons do
    desc "Watch for changes and rebuild icons.txt (requires listen gem)"
    task watch: :environment do
      system("bundle exec rails unmagic:icons:watch:poll")
    end

    namespace :watch do
      desc "Watch for changes with polling"
      task poll: :environment do
        require "listen"

        puts "[unmagic-icon] Watching for changes..."
        Unmagic::Icon::Scanner.write!

        # Watch source code for icon usage changes
        source_directories = [
          Rails.root.join("app"),
          Rails.root.join("lib"),
          Rails.root.join("spec"),
          Rails.root.join("test")
        ].select(&:exist?)

        source_listener = Listen.to(
          *source_directories,
          only: /\.(rb|erb|html|haml|slim)$/,
          force_polling: ENV["UNMAGIC_ICONS_WATCH_POLL"].present?
        ) do |modified, added, removed|
          if (modified + added + removed).any?
            puts "[unmagic-icon] Source files changed, rescanning for icon usage..."
            Unmagic::Icon.clear_known_icons!
            Unmagic::Icon::Scanner.write!
          end
        end

        # Watch icon files for changes
        icons_directory = Rails.root.join("app/assets/icons")
        icons_listener = nil
        if icons_directory.exist?
          icons_listener = Listen.to(
            icons_directory,
            only: /\.svg$/,
            force_polling: ENV["UNMAGIC_ICONS_WATCH_POLL"].present?
          ) do |modified, added, removed|
            if (modified + added + removed).any?
              puts "[unmagic-icon] Icon files changed, clearing library cache..."
              # Clear library cache to pick up new/changed/deleted SVG files
              Unmagic::Icon.instance_variable_set(:@libraries, nil)
              Unmagic::Icon.clear_known_icons!
              Unmagic::Icon::Scanner.write!
            end
          end
        end

        source_listener.start
        icons_listener&.start

        sleep
      rescue Interrupt
        puts "\n[unmagic-icon] Stopping watcher."
        source_listener&.stop
        icons_listener&.stop
      end
    end
  end
end
