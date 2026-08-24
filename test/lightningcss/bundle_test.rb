# frozen_string_literal: true

require "test_helper"

module LightningCSS
  class BundleTest < Minitest::Spec
    ENTRY = File.expand_path("../fixtures/bundle/entry.css", __dir__)
    MISSING = File.expand_path("../fixtures/bundle/missing.css", __dir__)

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
  end
end
