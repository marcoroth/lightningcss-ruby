# frozen_string_literal: true

require "test_helper"

module LightningCSS
  class WarningsTest < Minitest::Spec
    DEEP = ".a:deep(.b) { color: red }"
    WARNING = "'deep' is not recognized as a valid pseudo-class. Did you mean '::deep' (pseudo-element) or is this a typo? at :1:9"

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

    test "gives each warning as a warning" do
      assert_instance_of Warning, LightningCSS.transform(DEEP).warnings.first
    end

    test "says where a warning is, counting lines from 1 and columns from 0" do
      warning = LightningCSS.transform(".a { color: red; }\n.b, { color: blue; }\n", filename: "main.css", error_recovery: true).warnings.first

      assert_equal "Invalid empty selector", warning.message
      assert_equal "SelectorError", warning.type
      assert_equal Location.new(filename: "main.css", line: 2, column: 4), warning.location
    end

    test "keeps the message a warning had as a string" do
      warning = LightningCSS.transform(DEEP).warnings.first

      assert_equal WARNING, warning.to_s
      assert_equal WARNING, warning
      assert_equal warning, WARNING
    end

    test "has no filename for a stylesheet that was not given one" do
      assert_nil LightningCSS.transform(DEEP).warnings.first.location.filename
    end

    test "is equal to a warning with the same fields" do
      first, second = Array.new(2) { LightningCSS.transform(DEEP).warnings.first }

      assert_equal first, second
      assert_equal first.hash, second.hash
    end

    test "inspects as its message" do
      assert_equal "#<LightningCSS::Warning #{WARNING.inspect}>", LightningCSS.transform(DEEP).warnings.first.inspect
    end

    test "collects warnings as warnings when it parses" do
      warning = LightningCSS.parse(DEEP).warnings.first

      assert_instance_of Warning, warning
      assert_equal Location.new(filename: nil, line: 1, column: 8), warning.location
    end

    test "keeps its warnings to itself" do
      assert_predicate LightningCSS.transform(".a { color: red }").warnings, :frozen?
    end
  end
end
