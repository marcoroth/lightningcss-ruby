<h2 align="center">⚡ Lightning CSS for Ruby</h2>

<h4 align="center">An extremely fast CSS parser, transformer, bundler, and minifier.</h4>

<div align="center">Ruby bindings for <a href="https://lightningcss.dev">Lightning CSS</a>, the CSS toolchain written in Rust.</div><br/>

<p align="center">
  <a href="https://rubygems.org/gems/lightningcss"><img alt="Gem Version" src="https://img.shields.io/gem/v/lightningcss"></a>
  <a href="https://lightningcss.dev"><img alt="Documentation" src="https://img.shields.io/badge/lightningcss.dev-documentation-green"></a>
  <a href="https://github.com/marcoroth/lightningcss-ruby/blob/main/LICENSE.txt"><img alt="License" src="https://img.shields.io/github/license/marcoroth/lightningcss-ruby"></a>
  <a href="https://github.com/marcoroth/lightningcss-ruby/issues"><img alt="Issues" src="https://img.shields.io/github/issues/marcoroth/lightningcss-ruby"></a>
</p>

<br/>

### What is Lightning CSS for Ruby?

Ruby bindings for [Lightning CSS](https://lightningcss.dev), an extremely fast CSS parser, transformer, bundler, and minifier written in Rust.

Everything here is Lightning CSS doing the work. For what the options mean and what it can do, [lightningcss.dev](https://lightningcss.dev) is the reference.

### Installation

```bash
bundle add lightningcss
```

Precompiled gems are published for Linux (gnu and musl) and macOS, on x86_64, aarch64, and arm. On those platforms nothing is compiled at install time. Anywhere else the gem builds from source and needs the [Rust toolchain](https://rustup.rs).

### Usage

#### Transforming

```ruby
LightningCSS.transform(".a { color: #ff0000 }", minify: true).code
#=> ".a{color:red}"
```

#### Minifying

`minify` answers the code directly, for when the rest of the result is not interesting.

```ruby
LightningCSS.minify(".a { color: #ff0000 }")
#=> ".a{color:red}"
```

#### Targeting browsers

Give the browsers you support, each as its major version. Anything they cannot read is lowered, with the original kept after it so that a browser which understands it still wins.

```ruby
LightningCSS.transform(".a { color: lab(50% 40 59) }", targets: { chrome: 80 }, minify: true).code
#=> ".a{color:#bf5702;color:lab(50% 40 59)}"
```

#### Bundling

`bundle` resolves the `@import` statements a stylesheet was written with by reading the files they name, so it takes a path on disk to the entry stylesheet.

```ruby
LightningCSS.bundle("app/assets/stylesheets/application.css", minify: true).code
```

A bundle names every file it reads by the path it read it from, so it takes no `filename` and says so when given one.

It answers the same result a transform does. Every warning names the file it came from, and compiling as a CSS module renames the names in every file it read while exporting the ones the entry wrote. A file it imported is hashed on its own, so its names never collide with the entry's.

```ruby
result = LightningCSS.bundle("app/assets/stylesheets/application.css", css_modules: true)

result.exports
#=> {"application" => "_8Z4fiW_application"}

result.warnings.first
#=> "'deep' is not recognized as a valid pseudo-class. ... at app/assets/stylesheets/layout.css:0:9"
```

#### CSS modules

Compiling as a CSS module renames every class, id, `@keyframes`, and custom identifier, and reports what each name became.

```ruby
result = LightningCSS.transform(".card { color: red }", css_modules: true, minify: true)

result.code
#=> "._8Z4fiW_card{color:red}"

result.exports
#=> {"card" => "_8Z4fiW_card"}
```

Pass a hash instead of `true` to say how:

```ruby
LightningCSS.transform(".card {}", css_modules: { pattern: "scoped-[local]" }).exports
#=> {"card" => "scoped-card"}
```

#### Scoping

`scope` narrows every rule by a selector fragment, so a stylesheet only applies where that fragment matches. The fragment lands on the last compound of each selector, which is where a scope belongs.

```ruby
LightningCSS.transform(".card .title { color: red }", scope: "[data-scope-abc]", minify: true).code
#=> ".card .title[data-scope-abc]{color:red}"
```

Any single selector works as a fragment, so one carrying its own alternatives is fine:

```ruby
LightningCSS.transform(".title { color: red }", scope: ":where([s], [s] *)", minify: true).code
#=> ".title:where([s],[s] *){color:red}"
```

Keyframe selectors are left alone, and so is the inside of a functional pseudo class:

```ruby
LightningCSS.transform(".x:not(.y) { color: red }", scope: "[s]", minify: true).code
#=> ".x:not(.y)[s]{color:red}"
```

#### Style attributes

A style attribute is the list of declarations an element carries inline. It has no selectors and no at-rules around it, so it is its own grammar.

```ruby
LightningCSS.transform_style_attribute("color: #ff0000; border: none", minify: true).code
#=> "color:red;border:none"
```

Having no selectors and no names, it takes neither `scope` nor `css_modules`, and says so when given one.

#### Reusing options

`LightningCSS::Transformer` holds a set of options to use across many stylesheets. Options given to a call are merged over the ones it was built with.

```ruby
transformer = LightningCSS::Transformer.new(minify: true, targets: { chrome: 100 })

transformer.transform(".a { color: red }").code
transformer.transform(css, scope: "[data-scope-abc]").code
transformer.with(scope: "[s]")
```

It answers `call` as well, so it can be handed to anything expecting something callable.

### Options

| Option           | Type           | Description                                                                            |
|------------------|----------------|----------------------------------------------------------------------------------------|
| `filename`       | `String`       | The name to use in errors and warnings.                                                |
| `minify`         | `bool`         | Whether to print the result as small as it goes.                                       |
| `error_recovery` | `bool`         | Whether to carry on past a rule it cannot read. Off by default, so such a rule raises. |
| `targets`        | `Hash`         | The browsers being compiled for, each as its major version.                            |
| `css_modules`    | `bool`, `Hash` | Whether to compile as a CSS module, and how.                                           |
| `scope`          | `String`       | A selector fragment to narrow every rule by.                                           |

An option nobody reads is refused:

```ruby
LightningCSS.transform(".a {}", nonsense: true)
#=> LightningCSS::OptionError: Unknown option: nonsense
```

### Results

`transform`, `bundle`, and `transform_style_attribute` all answer a `LightningCSS::Result`.

```ruby
result = LightningCSS.transform(".a { color: #ff0000 }", minify: true)

result.code
#=> ".a{color:red}"

result.to_s
#=> ".a{color:red}"

result.exports
#=> nil

result.warnings
#=> []

result.warnings?
#=> false
```

`exports` is filled in when the stylesheet was compiled as a CSS module, and maps every name as it was written to the name it was compiled to:

```ruby
result = LightningCSS.transform(".card { color: red }", css_modules: true, minify: true)

result.code
#=> "._8Z4fiW_card{color:red}"

result.exports
#=> {"card" => "_8Z4fiW_card"}
```

`warnings` holds what Lightning CSS understood well enough to keep but not well enough to act on. They are worth reading, because what they describe is kept as written and then does nothing:

```ruby
result = LightningCSS.transform(".a:deep(.b) { color: red }", minify: true)

result.warnings?
#=> true

result.warnings.first
#=> "'deep' is not recognized as a valid pseudo-class. Did you mean '::deep' (pseudo-element) or is this a typo? at :0:9"

result.code
#=> ".a:deep(.b){color:red}"
```

### Development

The gem is a C extension over a Rust crate. `rust/` builds a static library and generates the C header with [cbindgen](https://github.com/mozilla/cbindgen), `ext/lightningcss/` wraps it, and `lib/` is the Ruby API over that.

```bash
bin/setup
bundle exec rake
```

`sig/` is generated from the `#:` annotations next to the code. Regenerate it with `rake rbs` after changing a signature, and CI checks that it matches.

### Acknowledgements

[Lightning CSS](https://lightningcss.dev) is written by [Devon Govett](https://github.com/devongovett) and maintained at [parcel-bundler/lightningcss](https://github.com/parcel-bundler/lightningcss). This gem only calls into it. Every CSS feature, browser target, and optimization comes from there.

Its selector engine, [`parcel_selectors`](https://github.com/parcel-bundler/lightningcss/tree/master/selectors), is a fork of the selector matching from [Servo](https://servo.org), by the Servo Project Developers.

Thank you to all of them.

### Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcoroth/lightningcss-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/marcoroth/lightningcss-ruby/blob/main/CODE_OF_CONDUCT.md).

Issues with CSS parsing, transforming, or minifying itself belong [upstream](https://github.com/parcel-bundler/lightningcss/issues), since this gem does none of that. Issues with the Ruby API, the build, or the bindings belong here.

### License

The Ruby, C, and Rust code in this gem is available under the terms of the [MIT License](https://opensource.org/licenses/MIT).

It builds against [Lightning CSS](https://github.com/parcel-bundler/lightningcss), which is licensed under the [MPL-2.0](https://www.mozilla.org/en-US/MPL/2.0/), and the native extension a precompiled gem ships has that code compiled into it. MPL-2.0 is a file-level copyleft license, so the source of the MPL-covered files stays available under the MPL. The upstream [LICENSE](https://github.com/parcel-bundler/lightningcss/blob/master/LICENSE) has the terms, and a copy travels with the gem in [`licenses/`](licenses) so that whoever received it has them in hand.
