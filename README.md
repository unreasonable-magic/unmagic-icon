# Unmagic::Icon

Inline SVG icons for Rails, with downloadable icon libraries.

## Features

- Render SVG icons inline as html-safe markup, straight into your views
- Resolve icons through `library/name` references, with aliases and glob patterns
- Per-library `manifest.json` for a default icon and alias mappings
- Caller-controlled attributes (`class`, `aria-*`, `data-*`, …) merged onto the `<svg>`
- Rails engine that registers a `unmagic_icon` view helper and sensible icon paths
- One-command downloads for popular icon sets (Heroicons, Lucide, Tabler, Feather, and more)
- A Rack app for browsing your configured libraries

## Installation

Add to your Gemfile:

```ruby
gem 'unmagic-icon'
```

## Usage

### In Rails views

The Rails engine registers a `unmagic_icon` helper and looks for icons in
`vendor/icons` and `app/assets/icons` (plus any engine-provided
`app/assets/icons`).

```erb
<%= unmagic_icon "heroicons/24-outline/star" %>
<%= unmagic_icon "lucide/check", class: "size-5 text-green-600" %>
<%= unmagic_icon "feather/menu", "aria-hidden": "true" %>
```

An icon reference is `library/name`. The library is the directory the icon
lives in (relative to a configured path), and the name is the SVG file without
its extension. Nested libraries work too — `heroicons/24-outline/star` is the
`star` icon in the `heroicons/24-outline` library.

The rendered `<svg>` always gets a `unmagic-icon` class and a
`data-unmagic-icon="library/name"` marker. Any caller class is appended, and
every other option is merged verbatim as an attribute — so accessibility
(`aria-hidden`, `aria-label`, `role`), `id`, and `data-*` are entirely up to you.

### Outside Rails

Configure the paths to look in, then resolve and render icons:

```ruby
require "unmagic_icon"

Unmagic::Icon.init do |config|
  config.paths = ["path/to/icons"]
end

icon = Unmagic::Icon.find("lucide/check")
icon.to_svg                       # => html-safe "<svg …>…</svg>"
icon.to_svg(class: "size-5")      # => with an extra class
icon.as_json                      # => { name: "lucide/check", svg: "<svg …>" }
```

References tolerate the emoji-style colon decoration, so `":lucide/check:"`
resolves the same as `"lucide/check"`.

### Aliases and defaults

Drop a `manifest.json` into a library directory to declare a default icon and
aliases. Aliases can be exact names or glob patterns (patterns are matched
longest-first, so the most specific wins):

```json
{
  "default": "file",
  "aliases": {
    "*.rb": "ruby",
    "*.test.tsx": "test",
    "*.tsx": "react"
  }
}
```

```ruby
Unmagic::Icon.find("material/app.rb").name   # => "material/ruby"
Unmagic::Icon.find("material/unknown").name  # => "material/file" (the default)
```

### Downloading icon libraries

The gem can fetch popular icon sets for you. List the ones you want in an
initializer:

```ruby
# config/initializers/unmagic_icon.rb
Unmagic::Icon.configure do |config|
  config.libraries = [:heroicons, :lucide, :feather]
end
```

Then download them (this also runs automatically during `assets:precompile`):

```bash
bin/rails unmagic:icons:install
```

Or grab a single library on demand:

```bash
bin/rails unmagic:icons:download[heroicons]
bin/rails unmagic:icons:download[silk,force]   # re-download even if present
```

Libraries are written to `config.download_path` (defaults to `vendor/icons`
under Rails), which keeps downloaded sets out of the asset pipeline — icons are
inlined via `File.read`, never served as assets.

Available libraries:

| Key                   | Title               | Description                                                                  |
| --------------------- | ------------------- | ---------------------------------------------------------------------------- |
| `heroicons`           | Heroicons           | Beautiful hand-crafted SVG icons by the makers of Tailwind CSS               |
| `devicons`            | Devicons            | Icons representing programming languages, designing & development tools      |
| `feather`             | Feather Icons       | Simply beautiful open source icons                                           |
| `tabler`              | Tabler Icons        | Over 5400 free SVG icons                                                     |
| `lucide`              | Lucide Icons        | Beautiful & consistent icons                                                 |
| `simple-icons`        | Simple Icons        | SVG icons for popular brands                                                 |
| `material-file-icons` | Material File Icons | Material Design file icons with filename/extension aliases                   |
| `silk`                | Silk Icons Scalable | The classic silk icon set recreated as SVG                                   |
| `coloured-icons`      | Coloured Icons      | Full-colour brand and technology logos                                       |
| `bootstrap-icons`     | Bootstrap Icons     | Official open source SVG icon library for Bootstrap                          |
| `octicons`            | Octicons            | Icons and icon font from GitHub                                              |
| `iconoir`             | Iconoir             | Free open source icons designed on a 24x24 grid                             |
| `material-design-icons` | Material Design Icons | 7400+ Material Design icons (Pictogrammers @mdi)                        |
| `phosphor`            | Phosphor Icons      | Flexible icon family with six weights (thin to fill, plus duotone)           |

### Browsing icons

`Unmagic::Icon::Web` is a small Rack app for browsing your configured
libraries. Mount it in your routes:

```ruby
mount Unmagic::Icon::Web => "/unmagic/icons"
```

## Development

After checking out the repo, install dependencies and run the tests:

```bash
bundle install
bundle exec rake spec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/unreasonable-magic/unmagic-icon.

## License

Released under the [MIT License](LICENSE).
