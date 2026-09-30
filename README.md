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
| `tabler`              | Tabler Icons        | Outline icons at `tabler/name`, filled icons at `tabler/filled/name`           |
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
| `lobe-icons`          | Lobe Icons          | Popular AI / LLM model brand logos and icons                                 |
| `svg-logos` | SVG Logos | Full-colour technology logos |
| `dashboard-icons` | Dashboard Icons | Service logos with available light/dark variants |
| `carbon-pictograms` | IBM Carbon Pictograms | IBM pictograms including IBM Cloud |
| `aws-architecture-icons` | AWS Architecture Icons | Official 64px service SVGs; AWS usage terms apply |

### Brand and cloud libraries

| Key | Pinned source | Example references |
| --- | --- | --- |
| `svg-logos` | [gilbarbara/logos](https://github.com/gilbarbara/logos/tree/37a6b807fd71c622efea27a9309b5d4edc792969), commit `37a6b807fd71c622efea27a9309b5d4edc792969` | `svg-logos/microsoft-power-bi`, `svg-logos/aws-cloudformation` |
| `dashboard-icons` | [homarr-labs/dashboard-icons](https://github.com/homarr-labs/dashboard-icons/tree/c716eb6798576923fa08e9b3e4125173148994ed), commit `c716eb6798576923fa08e9b3e4125173148994ed` | `dashboard-icons/powerbi`, `dashboard-icons/dagster-light`, `dashboard-icons/dagster-dark` |
| `carbon-pictograms` | [`@carbon/pictograms` 12.85.0](https://www.npmjs.com/package/@carbon/pictograms/v/12.85.0) | `carbon-pictograms/ibm--cloud` |
| `aws-architecture-icons` | Official July 31, 2026 ZIP, SHA-256 verified | `aws-architecture-icons/Arch_AWS-CloudFormation_64` |

Install these through the same initializer and task as other libraries:

```ruby
Unmagic::Icon.configure do |config|
  config.libraries = [:"svg-logos", :"dashboard-icons", :"carbon-pictograms", :"aws-architecture-icons"]
end
```

```bash
bin/rails unmagic:icons:install
# Or individually:
bin/rails 'unmagic:icons:download[svg-logos]'
bin/rails 'unmagic:icons:download[dashboard-icons]'
bin/rails 'unmagic:icons:download[carbon-pictograms]'
bin/rails 'unmagic:icons:download[aws-architecture-icons]'
```

```erb
<%= unmagic_icon "svg-logos/microsoft-power-bi", class: "size-6" %>
<%= unmagic_icon "svg-logos/aws-cloudformation" %>
<%= unmagic_icon "dashboard-icons/powerbi" %>
<%= unmagic_icon "dashboard-icons/dagster-light" %>
<%= unmagic_icon "dashboard-icons/dagster-dark" %>
<%= unmagic_icon "carbon-pictograms/ibm--cloud" %>
<%= unmagic_icon "aws-architecture-icons/Arch_AWS-CloudFormation_64" %>
<%= unmagic_icon "aws-architecture-icons/Arch_AWS-Cloud-Development-Kit_64" %>
<%= unmagic_icon "aws-architecture-icons/Arch_Amazon-SageMaker_64" %>
<%= unmagic_icon "aws-architecture-icons/Arch_Amazon-SageMaker-AI_64" %>
```

Names retain upstream spelling, case, punctuation, and variant suffixes. Select
light/dark assets explicitly; no automatic theme or product aliases are added.
SVG Logos' `slim` identifies the [Slim PHP framework](https://www.slimframework.com/),
**not** the Ruby template language. Unknown products raise instead of falling
back to a parent-company logo.

Downloads copy `logos/*.svg`, `svg/*.svg`, and `package/svg/*.svg`, respectively,
into their library directories. Dashboard's archive also contains PNG/WebP and
website assets (a large download); only its top-level SVG assets are installed.
Carbon's `@carbon/icons` 11.89.0 and `@carbon/pictograms` 12.85.0 packages were
both inspected: the former has a UI-sized `svg/32/ibm-cloud.svg`; the latter has
the IBM Cloud pictogram `svg/ibm--cloud.svg`. This integration selects the
pictograms family, excludes `src/svg` duplicates and JavaScript, and preserves
the double hyphen in its canonical name. The UI icons package is not installed.

SVG Logos, Dashboard Icons, and Carbon retain the upstream license and README alongside the SVGs,
plus a `manifest.json` recording its source, exact revision/version and license.
SVG Logos also retains `logos.json` with the original product identities and
links. The downloader does not execute npm scripts or upstream code. Existing
libraries and saved references are unchanged; rendering uses the same inline
SVG pipeline. As with existing libraries, downloaded SVGs are trusted assets,
not sanitized untrusted uploads.

#### Attribution and redistribution

These assets are not covered by this gem's MIT license. Keep the downloaded
legal files when redistributing them:

- **SVG Logos:** [CC0-1.0](https://github.com/gilbarbara/logos/blob/37a6b807fd71c622efea27a9309b5d4edc792969/LICENSE.txt).
  The upstream README identifies logos as their respective owners' property;
  CC0 does not waive trademark rights or third-party rights.
- **Dashboard Icons:** [Apache-2.0](https://github.com/homarr-labs/dashboard-icons/blob/c716eb6798576923fa08e9b3e4125173148994ed/LICENSE),
  with copyright attribution to Bjorn Lammers, Meier Lukas, Thomas Camlong and
  Homarr Labs. Preserve the license and applicable notices; identify changes
  when distributing modified files. The README limits brand representations
  to identification and disclaims endorsement.
- **IBM Carbon Pictograms:** Apache-2.0, as shipped in the pinned package's
  `LICENSE` and `README.md`. Preserve these and applicable copyright notices;
  identify modifications. Apache-2.0 does not grant general trademark rights.

Neither pinned Apache archive contains a separate `NOTICE` file. SVG bytes are
copied unchanged; rendering adds the gem's normal wrapper attributes. If you
redistribute rendered or otherwise modified assets, retain the license and
applicable notices and identify your modifications.

#### AWS Architecture Icons

The `aws-architecture-icons` downloader fetches the official July 31, 2026 ZIP
directly from AWS. It verifies SHA-256
`d2d166c453526471749d520e0db022c459abef759d2946cf2dd1d1c992dc6526`
before extraction and installs only `Architecture-Service-Icons_07312026/Arch_*/64/*.svg`.
Upstream filenames and SVG bytes remain unchanged. Other sizes, resource icons,
category icons, raster files, and macOS metadata are excluded.

AWS assets are proprietary. The [AWS Architecture Icons](https://aws.amazon.com/architecture/icons/)
page permits customers and partners to use them in architecture diagrams and
related materials. The [AWS Site Terms](https://aws.amazon.com/terms/) and
[AWS Intellectual Property License](https://aws.amazon.com/legal/aws-ip-license-terms/)
apply; downloading through this gem does not grant general redistribution or
trademark rights. No separate license file is included in the archive. The
installer writes `ATTRIBUTION.txt` with AWS ownership, source and terms links,
usage constraints and the extraction/rendering changes, plus provenance in
`manifest.json`. No AWS assets are bundled in the gem. Check AWS's terms for
your intended use, especially before redistributing an icon pack.

The inspected [official archive](https://d1.awsstatic.com/onedam/marketing-channels/website/public/shared/architecture-icon-release/Icon-package_07312026.5846e92413caa21490223536cc97f1269e44fa92.zip)
contains the following distinct service SVGs under
`Architecture-Service-Icons_07312026/`:

| Product | Category / exact filename |
| --- | --- |
| CloudFormation | `Arch_Management-Tools/64/Arch_AWS-CloudFormation_64.svg` |
| AWS Cloud Development Kit | `Arch_Developer-Tools/64/Arch_AWS-Cloud-Development-Kit_64.svg` |
| Amazon SageMaker | `Arch_Analytics/64/Arch_Amazon-SageMaker_64.svg` |
| Amazon SageMaker AI | `Arch_Artificial-Intelligence/64/Arch_Amazon-SageMaker-AI_64.svg` |
| Amazon SageMaker Studio Lab | `Arch_Artificial-Intelligence/64/Arch_Amazon-SageMaker-Studio-Lab_64.svg` |
| Amazon SageMaker Ground Truth | `Arch_Artificial-Intelligence/64/Arch_Amazon-SageMaker-Ground-Truth_64.svg` |

Each filename above is installed at `aws-architecture-icons/<filename-without-.svg>`.
For example, Studio Lab is `aws-architecture-icons/Arch_Amazon-SageMaker-Studio-Lab_64`
and Ground Truth is `aws-architecture-icons/Arch_Amazon-SageMaker-Ground-Truth_64`.
SageMaker and SageMaker AI remain distinct, with no ambiguous `sagemaker` alias
or fallback to AWS's company logo. Source and licensing review: 2026-09-30.

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

To replay the brand-library browser demo (downloads on first run):

```bash
bundle exec rackup demo/brand_icons.ru -p 5701 -o 127.0.0.1
```

Open `http://localhost:5701/demo` and click **Replay**. The ten steps check
Power BI, CloudFormation, CDK, the distinct SageMaker products, Dagster in both
themes, IBM Cloud, and the existing
`lucide/check` reference through the gallery.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/unreasonable-magic/unmagic-icon.

## License

Released under the [MIT License](LICENSE).
