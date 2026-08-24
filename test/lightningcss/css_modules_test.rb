# frozen_string_literal: true

require "test_helper"

module LightningCSS
  class CSSModulesTest < Minitest::Spec
    ANIMATED = ".card { animation: spin 1s } @keyframes spin { from { opacity: 0 } }"

    test "renames what it compiled and reports the mapping" do
      result = LightningCSS.transform(".card { color: red }", css_modules: true, minify: true)

      assert_equal "._8Z4fiW_card{color:red}", result.code
      assert_equal({ "card" => "_8Z4fiW_card" }, result.exports)
    end

    test "renames a keyframes name and the animation pointing at it" do
      result = LightningCSS.transform(ANIMATED, css_modules: true, minify: true)

      assert_equal "._8Z4fiW_card{animation:1s _8Z4fiW_spin}@keyframes _8Z4fiW_spin{0%{opacity:0}}", result.code
      assert_equal({ "spin" => "_8Z4fiW_spin", "card" => "_8Z4fiW_card" }, result.exports)
    end

    test "honours a pattern" do
      result = LightningCSS.transform(".card { color: red }", css_modules: { pattern: "scoped-[local]" }, minify: true)

      assert_equal ".scoped-card{color:red}", result.code
      assert_equal({ "card" => "scoped-card" }, result.exports)
    end

    test "leaves everything as written when it was not asked for" do
      result = LightningCSS.transform(ANIMATED, minify: true)

      assert_equal ".card{animation:1s spin}@keyframes spin{0%{opacity:0}}", result.code
      assert_nil result.exports
    end

    test "refuses a pattern it cannot read" do
      error = assert_raises(LightningCSS::OptionError) do
        LightningCSS.transform(".a {}", css_modules: { pattern: "[nonsense]" })
      end

      assert_equal 'Invalid CSS modules pattern "[nonsense]"', error.message
    end
  end
end
