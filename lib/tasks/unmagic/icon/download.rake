# frozen_string_literal: true

namespace :unmagic do
  namespace :icons do
    desc "Download popular icon libraries"
    task :download, %i[library force] => :environment do |_task, args|
      require_relative "../../../unmagic/icon/library/source"

      library = args[:library]&.strip
      force = args[:force] == "force"

      if library.nil? || library.empty?
        puts "Error: Please specify a library to download"
        puts "Available libraries:"
        Unmagic::Icon::Library::Source.all.each do |source|
          puts "  #{source.key.to_s.ljust(20)} - #{source.description}"
        end
        puts "\nUsage: rails unmagic:icons:download[heroicons]"
        puts "       rails unmagic:icons:download[silk,force]"
        exit 1
      end

      Unmagic::Icon::Library::Source.find(library).new.download(force: force)
    end
  end
end
