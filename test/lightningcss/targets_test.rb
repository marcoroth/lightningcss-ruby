# frozen_string_literal: true

require "test_helper"

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
  end
end
