# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New downloadable icon libraries: `coloured-icons` (full-colour brand/tech
  logos), `bootstrap-icons`, `octicons`, `iconoir`, `material-design-icons`
  (Pictogrammers @mdi), and `phosphor` (six weights flattened into one set)

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

[Unreleased]: https://github.com/unreasonable-magic/unmagic-icon/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/unreasonable-magic/unmagic-icon/releases/tag/v0.1.0
