# frozen_string_literal: true

namespace :unmagic do
  namespace :icons do
    desc "Scan codebase for icon usage and build icons.txt"
    task build: :environment do
      Unmagic::Icon::Scanner.write!
    end
  end
end
