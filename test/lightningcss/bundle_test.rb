# frozen_string_literal: true

require "test_helper"

module LightningCSS
  class BundleTest < Minitest::Spec
    ENTRY = File.expand_path("../fixtures/bundle/entry.css", __dir__)
    MISSING = File.expand_path("../fixtures/bundle/missing.css", __dir__)
    WARNED = File.expand_path("../fixtures/bundle/warned.css", __dir__)
    BROKEN = File.expand_path("../fixtures/bundle/broken.css", __dir__)
    UNREADABLE = File.expand_path("../fixtures/bundle/nested/broken.css", __dir__)
    IMPORTED = File.expand_path("../fixtures/bundle/nested/warned.css", __dir__)
    WARNING = "'deep' is not recognized as a valid pseudo-class. Did you mean '::deep' (pseudo-element) or is this a typo? at #{IMPORTED}:0:9".freeze

    test "resolves the imports a stylesheet was written with, in the order it imported them" do
      code = LightningCSS.bundle(ENTRY, minify: true).code

      assert_equal ":root{--brand:red}.layout{display:grid}.entry{color:var(--brand)}", code
    end

    test "narrows everything it bundled by a scope" do
      code = LightningCSS.bundle(ENTRY, minify: true, scope: "[s]").code

      assert_equal ":root[s]{--brand:red}.layout[s]{display:grid}.entry[s]{color:var(--brand)}", code
    end

    test "raises a bundle error when a file it was sent to read is not there" do
      error = assert_raises(LightningCSS::BundleError) { LightningCSS.bundle(MISSING) }

      assert_equal "No such file or directory (os error 2)", error.message
    end

    test "a bundle error is an error" do
      assert_operator LightningCSS::BundleError, :<, LightningCSS::Error
    end

    test "a transformer carries its options into a bundle" do
      code = Transformer.new(minify: true).bundle(ENTRY).code

      assert_equal ":root{--brand:red}.layout{display:grid}.entry{color:var(--brand)}", code
    end

    test "renames every name it bundled, and reports the ones the entry wrote" do
      result = LightningCSS.bundle(ENTRY, css_modules: { pattern: "bundled-[local]" }, minify: true)

      assert_equal ":root{--brand:red}.bundled-layout{display:grid}.bundled-entry{color:var(--brand)}", result.code
      assert_equal({ "entry" => "bundled-entry" }, result.exports)
    end

    test "hashes every file it bundled on its own, so two of them never collide" do
      code = LightningCSS.bundle(ENTRY, css_modules: true, minify: true).code

      entry = code[/\.(\w+)_entry\{/, 1]
      layout = code[/\.(\w+)_layout\{/, 1]

      refute_nil entry
      refute_nil layout
      refute_equal entry, layout
    end

    test "reports no exports when it was not asked to compile a CSS module" do
      assert_nil LightningCSS.bundle(ENTRY, minify: true).exports
    end

    test "reports what it kept but did not understand, and which file wrote it" do
      result = LightningCSS.bundle(WARNED, minify: true)

      assert_equal [WARNING], result.warnings
      assert_predicate result, :warnings?
    end

    test "keeps the rule it warned about" do
      assert_includes LightningCSS.bundle(WARNED, minify: true).code, ".a:deep(.b){color:red}"
    end

    test "reports none for a bundle it fully understood" do
      result = LightningCSS.bundle(ENTRY, minify: true)

      assert_empty result.warnings
      refute_predicate result, :warnings?
    end

    test "raises a parse error for CSS it could not read, wherever it imported it from" do
      error = assert_raises(LightningCSS::ParseError) { LightningCSS.bundle(BROKEN) }

      assert_equal "Invalid empty selector at #{UNREADABLE}:0:1", error.message
    end

    test "refuses a filename, naming every file it reads by the path it read it from" do
      error = assert_raises(LightningCSS::OptionError) { LightningCSS.bundle(ENTRY, filename: "x.css") }

      assert_equal "filename is not an option for a bundle", error.message
    end

    test "refuses a filename a transformer was built with, the same way" do
      error = assert_raises(LightningCSS::OptionError) { Transformer.new(filename: "x.css").bundle(ENTRY) }

      assert_equal "filename is not an option for a bundle", error.message
    end
  end
end
