# frozen_string_literal: true

module Unmagic
  class Icon
    class Library
      class Source
        # LobeHub's AI/LLM brand logos, sourced from the static-svg npm package
        # rather than the repo (the repo only ships React components). Each brand
        # comes in up to three variants, distinguished by filename suffix: the
        # bare mark (openai), the full-colour mark (openai-color), and the
        # wordmark (openai-text).
        class LobeIcons < Source
          key :"lobe-icons"
          title "Lobe Icons"
          description "Popular AI / LLM model brand logos and icons"
          url "https://registry.npmjs.org/@lobehub/icons-static-svg/-/icons-static-svg-1.95.1.tgz"
          archive :tgz
          dir "lobe-icons"
          extract "package/icons/*.svg"
        end
      end
    end
  end
end
