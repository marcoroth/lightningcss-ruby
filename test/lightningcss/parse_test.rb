# frozen_string_literal: true

require "test_helper"

module LightningCSS
  class ParseTest < Minitest::Spec
    SOURCE = ".a { color: red }"

    test "answers the stylesheet as Lightning CSS serializes it" do
      result = LightningCSS.parse(SOURCE)

      assert_equal ["rules", "sources", "sourceMapUrls", "licenseComments"], result.stylesheet.keys
      assert_equal "style", result.stylesheet.dig("rules", 0, "type")
    end

    test "keeps the source it read" do
      assert_equal SOURCE, LightningCSS.parse(SOURCE).source
    end

    test "answers the stylesheet as a node" do
      root = LightningCSS.parse(SOURCE).root

      assert_instance_of Node, root
      assert_equal "stylesheet", root.type
    end

    test "names the file it read" do
      assert_equal ["a.css"], LightningCSS.parse(SOURCE, filename: "a.css").root.sources
    end

    test "collects warnings" do
      result = LightningCSS.parse(".a:deep(.b) { color: red }")

      assert_predicate result, :warnings?
      assert_match "'deep' is not recognized as a valid pseudo-class", result.warnings.first
    end

    test "raises on a stylesheet it cannot read" do
      error = assert_raises(LightningCSS::ParseError) { LightningCSS.parse(". { color: red }") }

      assert_equal 'Expected identifier in class selector, got WhiteSpace(" ") at :0:2', error.message
    end

    test "recovers when asked to" do
      result = LightningCSS.parse(".a { color: red } @media (min-width: ) { .b { color: blue } } .c { color: green }", error_recovery: true)

      assert_predicate result, :warnings?
    end

    test "refuses options that only matter to printing" do
      error = assert_raises(LightningCSS::OptionError) { LightningCSS.parse(SOURCE, minify: true) }

      assert_equal "minify is not an option for a parse", error.message
    end

    test "prints what it parsed" do
      assert_equal "#<LightningCSS::ParseResult rules=1>", LightningCSS.parse(SOURCE).inspect
    end

    test "is frozen" do
      result = LightningCSS.parse(SOURCE)

      assert_predicate result, :frozen?
      assert_predicate result.stylesheet, :frozen?
    end

    test "is reachable from a transformer, which keeps only the options a parse reads" do
      transformer = LightningCSS::Transformer.new(minify: true, filename: "a.css")

      assert_equal ["a.css"], transformer.parse(SOURCE).root.sources
    end
  end
end
