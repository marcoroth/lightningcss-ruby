# frozen_string_literal: true

require "test_helper"

module LightningCSS
  class StyleAttributeTest < Minitest::Spec
    test "transforms a declaration list without a selector around it" do
      result = LightningCSS.transform_style_attribute("color: #ff0000; border: none", minify: true)

      assert_equal "color:red;border:none", result.code
    end

    test "refuses a scope, having no selectors to narrow" do
      error = assert_raises(LightningCSS::OptionError) do
        LightningCSS.transform_style_attribute("color: red", scope: "[s]")
      end

      assert_equal "scope is not an option for a style attribute", error.message
    end

    test "refuses css modules, having no names to compile" do
      error = assert_raises(LightningCSS::OptionError) do
        LightningCSS.transform_style_attribute("color: red", css_modules: true)
      end

      assert_equal "css_modules is not an option for a style attribute", error.message
    end

    test "reads a target, which acts on declarations" do
      code = LightningCSS.transform_style_attribute("color: lab(50% 40 59)", targets: { chrome: 80 }, minify: true).code

      assert_equal "color:#bf5702;color:lab(50% 40 59)", code
    end

    test "is a different grammar from a stylesheet" do
      error = assert_raises(LightningCSS::ParseError) do
        LightningCSS.transform_style_attribute(".a { color: red }")
      end

      assert_equal "Unexpected token Delim('.') at :0:1", error.message
    end

    test "has no names to compile, so it reports no exports" do
      result = LightningCSS.transform_style_attribute("color: red")

      assert_nil result.exports
      assert_empty result.warnings
    end
  end
end
