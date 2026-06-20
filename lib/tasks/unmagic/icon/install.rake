# frozen_string_literal: true

namespace :unmagic do
  namespace :icons do
    desc "Download every icon library listed in Unmagic::Icon.configuration.libraries"
    task install: :environment do
      require_relative "../../../unmagic/icon/library/source"

      libraries = Array(Unmagic::Icon.configuration.libraries)

      if libraries.empty?
        puts "No icon libraries configured. Set Unmagic::Icon.configuration.libraries in an initializer."
      else
        libraries.each { |name| Unmagic::Icon::Library::Source.find(name).new.download }
      end
    end
  end
end

# Fetch the configured icon libraries as part of asset precompilation, so they
# arrive through normal Rails operations (e.g. the production image build) rather
# than a separate manual step. The download skips libraries already present, and
# it's a no-op when none are configured. The prerequisite resolves at invocation
# time, so this works regardless of when assets:precompile is defined.
task "assets:precompile" => "unmagic:icons:install"
