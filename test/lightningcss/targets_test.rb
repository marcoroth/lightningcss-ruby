# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module LightningCSS
  class TargetsTest < Minitest::Spec
    LAB = ".a { color: lab(50% 40 59) }"

    test "lowers a colour a target cannot read, and keeps the original after it" do
      code = LightningCSS.transform(LAB, targets: { chrome: 80 }, minify: true).code

      assert_equal ".a{color:#bf5702;color:lab(50% 40 59)}", code
    end

    test "leaves it alone for a target that can read it" do
      code = LightningCSS.transform(LAB, targets: { chrome: 130 }, minify: true).code

      assert_equal ".a{color:lab(50% 40 59)}", code
    end

    test "leaves it alone when it was given no target at all" do
      assert_equal ".a{color:lab(50% 40 59)}", LightningCSS.transform(LAB, minify: true).code
    end

    test "lowers a colour for its targets when it was not asked to minify" do
      code = LightningCSS.transform(LAB, targets: { chrome: 80 }).code

      assert_equal ".a {\n  color: #bf5702;\n  color: lab(50% 40 59);\n}\n", code
    end

    test "adds the prefixes its targets need when it was not asked to minify" do
      code = LightningCSS.transform(".a { user-select: none }", targets: { safari: 12 }).code

      assert_equal ".a {\n  -webkit-user-select: none;\n  user-select: none;\n}\n", code
    end

    OKLCH = ".a { color: oklch(60% .2 30) }"

    test "reads an integer as a major version" do
      code = LightningCSS.transform(OKLCH, targets: { safari: 15 }, minify: true).code

      assert_equal ".a{color:lab(51.6908% 61.9679 48.0969)}", code
    end

    test "reads a float as a major and minor version" do
      code = LightningCSS.transform(OKLCH, targets: { safari: 15.4 }, minify: true).code

      assert_equal ".a{color:oklch(60% .2 30)}", code
    end

    test "reads a string as a major and minor version" do
      code = LightningCSS.transform(OKLCH, targets: { safari: "15.4" }, minify: true).code

      assert_equal ".a{color:oklch(60% .2 30)}", code
    end

    test "reads a string with a patch version" do
      code = LightningCSS.transform(OKLCH, targets: { ios_saf: "15.4.1" }, minify: true).code

      assert_equal ".a{color:oklch(60% .2 30)}", code
    end

    test "reads a minor version for a property it would otherwise prefix" do
      assert_equal ".a{-webkit-appearance:none;appearance:none}", LightningCSS.transform(".a { appearance: none }", targets: { safari: 15 }, minify: true).code
      assert_equal ".a{appearance:none}", LightningCSS.transform(".a { appearance: none }", targets: { safari: "15.4" }, minify: true).code
    end

    test "reads a minor version for a shorthand it would otherwise expand" do
      assert_equal ".a{top:0;bottom:0;left:0;right:0}", LightningCSS.transform(".a { inset: 0 }", targets: { safari: 14 }, minify: true).code
      assert_equal ".a{inset:0}", LightningCSS.transform(".a { inset: 0 }", targets: { safari: 14.1 }, minify: true).code
    end

    test "applies a minor version to a style attribute" do
      code = LightningCSS.transform_style_attribute("appearance: none", targets: { safari: "15.4" }, minify: true).code

      assert_equal "appearance:none", code
    end

    ["15.a", "15.4.1.2", "", "-1", "15.256", "65536"].each do |version|
      test "raises an option error for the version #{version.inspect}" do
        error = assert_raises(OptionError) { LightningCSS.transform(".a{}", targets: { safari: version }) }

        assert_equal "Invalid version #{version.inspect} for safari in targets", error.message
      end
    end

    test "raises an option error for a browser it does not know" do
      error = assert_raises(OptionError) { LightningCSS.transform(".a{}", targets: { safar: 15 }) }

      assert_equal "Unknown browser in targets: safar", error.message
    end

    test "names every browser it does not know, in order" do
      error = assert_raises(OptionError) { LightningCSS.transform(".a{}", targets: { netscape: 4, chrome: 100, mosaic: 1 }) }

      assert_equal "Unknown browsers in targets: mosaic, netscape", error.message
    end

    test "raises for a browser it does not know before reading any version" do
      error = assert_raises(OptionError) { LightningCSS.transform(".a{}", targets: { safari: "x", safar: 15 }) }

      assert_equal "Unknown browser in targets: safar", error.message
    end

    test "reads ios as ios_saf" do
      code = LightningCSS.transform(".a { color: oklch(60% .2 30) }", targets: { ios: "15.4" }, minify: true).code

      assert_equal ".a{color:oklch(60% .2 30)}", code
    end

    test "raises an option error for a negative version" do
      error = assert_raises(OptionError) { LightningCSS.transform(".a{}", targets: { safari: -1 }) }

      assert_equal "Invalid version -1 for safari in targets", error.message
    end

    test "raises an option error for a major version too large to encode" do
      error = assert_raises(OptionError) { LightningCSS.transform(".a{}", targets: { safari: 65_536 }) }

      assert_equal "Invalid version 65536 for safari in targets", error.message
    end

    test "applies its targets to a bundle it was not asked to minify" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "a.css")
        File.write(path, ".a { user-select: none }")

        code = LightningCSS.bundle(path, targets: { safari: 12 }).code

        assert_equal ".a {\n  -webkit-user-select: none;\n  user-select: none;\n}\n", code
      end
    end
  end
end
