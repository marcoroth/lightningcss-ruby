# frozen_string_literal: true

require "test_helper"

module LightningCSS
  class TransformerTest < Minitest::Spec
    test "transforms with the options it was built with" do
      assert_equal ".a{color:red}", Transformer.new(minify: true).transform(".a { color: #ff0000 }").code
    end

    test "merges what a call gives it over what it was built with" do
      code = Transformer.new(minify: true).transform(".title { color: red }", scope: "[s]").code

      assert_equal ".title[s]{color:red}", code
    end

    test "lets a call override an option it was built with" do
      code = Transformer.new(minify: true).transform(".a { color: red }", minify: false).code

      assert_equal ".a {\n  color: red;\n}\n", code
    end

    test "answers call, so it can be handed to anything callable" do
      transformer = Transformer.new(minify: true)

      assert_equal ".title[s]{color:red}", transformer.call(".title { color: red }", scope: "[s]").code
    end

    test "builds another transformer from itself, leaving the first alone" do
      base = Transformer.new(minify: true)
      scoped = base.with(scope: "[s]")

      assert_equal ".title[s]{color:red}", scoped.transform(".title { color: red }").code
      assert_equal ".title{color:red}", base.transform(".title { color: red }").code
    end

    test "keeps its options to itself" do
      transformer = Transformer.new(minify: true)

      assert_predicate transformer, :frozen?
      assert_predicate transformer.options, :frozen?
      assert_equal({ minify: true }, transformer.options)
    end

    test "carries its options into a style attribute" do
      assert_equal "color:red", Transformer.new(minify: true).transform_style_attribute("color: #ff0000").code
    end

    test "minifies through the shorthand" do
      assert_equal ".a{color:red}", Transformer.new.minify(".a { color: #ff0000 }")
    end

    test "prints what it was built with" do
      assert_equal "#<LightningCSS::Transformer {minify: true}>", Transformer.new(minify: true).inspect
    end
  end
end
