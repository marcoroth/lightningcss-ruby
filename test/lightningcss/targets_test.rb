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
