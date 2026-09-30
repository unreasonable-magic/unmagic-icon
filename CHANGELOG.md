# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.1] - 2026-09-30

### Changed
- Update Feather to 4.29.2, Tabler to 3.48.0, Lucide to 1.49.0,
  Simple Icons to 16.33.0, Material File Icons to 5.38.1, Octicons to
  19.38.0, Iconoir to 7.12.1, and Lobe Icons to 1.95.1.
- Download Tabler and Octicons from their official npm SVG packages.

### Fixed
- Extract Tabler's nested SVG directories, with outline icons at `tabler/name`
  and filled variants at `tabler/filled/name`, avoiding filename collisions.
- Download Silk from its existing `master` branch.

## [0.3.0] - 2026-07-31

### Added
- New downloadable icon library: `lobe-icons` (AI/LLM brand logos from
  LobeHub, with `-color` and `-text` variants alongside each bare mark)

## [0.2.1] - 2026-07-14

### Changed
- Archives are now extracted in pure Ruby (rubyzip for zips, stdlib
  `Gem::Package::TarReader`/`Zlib` for tarballs) instead of shelling out to
  `unzip`/`tar`, so `unmagic:icons:install` works in minimal containers —
  such as Rails' default slim Docker image — where those binaries aren't
  installed. Extraction also guards against zip-slip path traversal.

### Added
- Runtime dependency on `rubyzip` (>= 2.3)

## [0.2.0] - 2026-06-22

### Added
- New downloadable icon libraries: `coloured-icons` (full-colour brand/tech
  logos), `bootstrap-icons`, `octicons`, `iconoir`, `material-design-icons`
  (Pictogrammers @mdi), and `phosphor` (six weights flattened into one set)
- Server-side search in the `Unmagic::Icon::Web` Rack app

## [0.1.0] - 2026-06-21

### Added
- Initial release
- `Unmagic::Icon` for loading an SVG asset and rendering it inline as
  html-safe markup, with a `unmagic-icon` class, a `data-unmagic-icon` marker,
  and caller-supplied attributes (`class`, `aria-*`, `data-*`, etc.) merged onto
  the `<svg>` element; rendered markup is cached when no options are passed
- `Unmagic::Icon.find` to resolve a `library/name` reference (tolerating the
  emoji-style `:library/name:` decoration) to an icon
- `Unmagic::Icon::Library` with on-disk icon discovery and an optional
  `manifest.json` declaring a `default` icon and `aliases` (exact strings plus
  glob patterns, matched longest-first)
- `Unmagic::Icon::Library::Registry` that builds libraries from configured
  paths, supporting nested library names and a `prefix:path` syntax
- `Unmagic::Icon::Configuration` with `paths`, `libraries`, and a `download_path`
  defaulting to `vendor/icons` under Rails
- Rails integration via `Unmagic::Icon::Engine`: registers the `unmagic_icon`
  view helper and configures default icon paths (including engine-provided icons)
- `Unmagic::Icon::Library::Source`, a DSL-driven downloader for popular icon
  sets — Heroicons, Devicons, Feather, Tabler, Lucide, Simple Icons, Material
  File Icons, and Silk
- Rake tasks `unmagic:icons:install` (downloads the configured libraries, and
  hooks into `assets:precompile`) and `unmagic:icons:download[library]`
- `Unmagic::Icon::Web`, a Rack app for browsing the configured icon libraries

[Unreleased]: https://github.com/unreasonable-magic/unmagic-icon/compare/v0.3.1...HEAD
[0.3.1]: https://github.com/unreasonable-magic/unmagic-icon/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/unreasonable-magic/unmagic-icon/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/unreasonable-magic/unmagic-icon/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/unreasonable-magic/unmagic-icon/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/unreasonable-magic/unmagic-icon/releases/tag/v0.1.0
