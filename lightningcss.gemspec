# frozen_string_literal: true

require_relative "lib/lightningcss/version"

Gem::Specification.new do |spec|
  spec.name = "lightningcss"
  spec.version = LightningCSS::VERSION
  spec.authors = ["Marco Roth"]
  spec.email = ["marco.roth@intergga.ch"]

  spec.summary = "An extremely fast CSS parser, transformer, bundler, and minifier."
  spec.description = "Ruby bindings for Lightning CSS, an extremely fast CSS parser, transformer, bundler, and minifier."
  spec.homepage = "https://github.com/marcoroth/lightningcss-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.require_paths = ["lib"]

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/marcoroth/lightningcss-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/marcoroth/lightningcss-ruby/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "lightningcss.gemspec",
    "LICENSE.txt",
    "licenses/*.txt",
    "licenses/README.md",
    "README.md",
    "lib/**/*.rb",
    "sig/**/*.rbs",
    "ext/lightningcss/extconf.rb",
    "ext/lightningcss/lightningcss.c",
    "ext/lightningcss/include/**/*.h",
    "rust/Cargo.toml",
    "rust/Cargo.lock",
    "rust/build.rs",
    "rust/cbindgen.toml",
    "rust/rustfmt.toml",
    "rust/src/**/*.rs"
  ]

  spec.extensions = ["ext/lightningcss/extconf.rb"]
end
