# frozen_string_literal: true

require "test_helper"

module LightningCSS
  class WarningsTest < Minitest::Spec
    DEEP = ".a:deep(.b) { color: red }"
    WARNING = "'deep' is not recognized as a valid pseudo-class. Did you mean '::deep' (pseudo-element) or is this a typo? at :0:9"

    test "reports what it kept but did not understand" do
      result = LightningCSS.transform(DEEP, minify: true)

      assert_equal [WARNING], result.warnings
      assert_predicate result, :warnings?
    end

    test "keeps the rule it warned about" do
      assert_equal ".a:deep(.b){color:red}", LightningCSS.transform(DEEP, minify: true).code
    end

    test "prints its warnings when it has them" do
      result = LightningCSS.transform(DEEP, minify: true)

      assert_equal %(#<LightningCSS::Result code=".a:deep(.b){color:red}" warnings=[#{WARNING.inspect}]>), result.inspect
    end

    test "reports none for a stylesheet it fully understood" do
      result = LightningCSS.transform(".a { color: red }", minify: true)

      assert_empty result.warnings
      refute_predicate result, :warnings?
    end

    test "keeps its warnings to itself" do
      assert_predicate LightningCSS.transform(".a { color: red }").warnings, :frozen?
    end
  end
end
