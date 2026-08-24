# frozen_string_literal: true

require "test_helper"

module LightningCSS
  class TransformTest < Minitest::Spec
    test "returns the stylesheet it was given" do
      assert_equal ".a {\n  color: red;\n}\n", LightningCSS.transform(".a { color: red }").code
    end

    test "minifies when asked to" do
      assert_equal ".a{color:red}", LightningCSS.transform(".a { color: #ff0000 }", minify: true).code
    end

    test "answers with a result that prints as its code" do
      result = LightningCSS.transform(".a { color: red }", minify: true)

      assert_equal ".a{color:red}", result.to_s
      assert_nil result.exports
      assert_empty result.warnings
    end

    test "minify shorthand returns the code directly" do
      assert_equal ".a{color:red}", LightningCSS.minify(".a { color: #ff0000 }")
    end

    test "prints what a result is" do
      result = LightningCSS.transform(".a { color: red }", minify: true)

      assert_equal %(#<LightningCSS::Result code=".a{color:red}">), result.inspect
    end
  end
end
