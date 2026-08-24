# frozen_string_literal: true

require "test_helper"

module LightningCSS
  class OptionsTest < Minitest::Spec
    test "writes what it was given as JSON" do
      assert_equal '{"minify":true}', Options.new(minify: true).to_json
    end

    test "writes nothing when it was given nothing" do
      assert_equal "{}", Options.new.to_json
    end

    test "reads a string key as the option it names" do
      assert_equal({ minify: true }, Options.new("minify" => true).to_h)
    end

    test "drops an option that was given as nil" do
      assert_equal "{}", Options.new(scope: nil).to_json
    end

    test "reads css_modules true as the settings it already has" do
      assert_equal({ css_modules: {} }, Options.new(css_modules: true).to_h)
    end

    test "reads css_modules false as not at all" do
      assert_equal({}, Options.new(css_modules: false).to_h)
    end

    test "keeps css_modules settings as written" do
      assert_equal({ css_modules: { pattern: "[local]" } }, Options.new(css_modules: { pattern: "[local]" }).to_h)
    end

    test "refuses an option nobody reads" do
      error = assert_raises(OptionError) { Options.new(nonsense: true) }

      assert_equal "Unknown option: nonsense", error.message
    end

    test "names every option nobody reads" do
      error = assert_raises(OptionError) { Options.new(nope: 1, nah: 2) }

      assert_equal "Unknown options: nope, nah", error.message
    end

    test "knows what the native library reads" do
      assert_equal [:filename, :minify, :error_recovery, :targets, :css_modules, :scope], Options::KNOWN
    end

    test "keeps what it read to itself" do
      options = Options.new(minify: true)

      assert_predicate options, :frozen?
      assert_predicate options.to_h, :frozen?
    end

    test "prints what it read" do
      assert_equal "#<LightningCSS::Options {minify: true}>", Options.new(minify: true).inspect
    end

    test "serializes in one step" do
      assert_equal '{"minify":true}', Options.serialize({ minify: true })
    end

    test "knows what a style attribute reads" do
      assert_equal [:filename, :minify, :error_recovery, :targets], Options::STYLE_ATTRIBUTE
    end

    test "refuses an option that has nothing to act on" do
      error = assert_raises(OptionError) do
        Options.serialize({ scope: "[s]" }, allowed: Options::STYLE_ATTRIBUTE, subject: "a style attribute")
      end

      assert_equal "scope is not an option for a style attribute", error.message
    end

    test "names every option that has nothing to act on" do
      error = assert_raises(OptionError) do
        Options.serialize({ scope: "[s]", css_modules: true }, allowed: Options::STYLE_ATTRIBUTE, subject: "a style attribute")
      end

      assert_equal "scope, css_modules are not options for a style attribute", error.message
    end

    test "refuses an unknown option ahead of an unsupported one" do
      error = assert_raises(OptionError) do
        Options.serialize({ nonsense: 1, scope: "[s]" }, allowed: Options::STYLE_ATTRIBUTE, subject: "a style attribute")
      end

      assert_equal "Unknown option: nonsense", error.message
    end
  end
end
