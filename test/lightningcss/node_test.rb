# frozen_string_literal: true

require "test_helper"

module LightningCSS
  class NodeTest < Minitest::Spec
    SOURCE = ".card .title:hover { color: #f00; margin: 0 auto }\n@media (min-width: 600px) { .a { --x: 1px } }"

    def root
      LightningCSS.parse(SOURCE).root
    end

    test "wraps the stylesheet" do
      assert_equal "stylesheet", root.type
      assert_nil root.parent
    end

    test "names a rule the way a visitor answers it" do
      rule = root.rules.first

      assert_equal "style", rule.type
      assert_predicate rule, :rule?
      assert_equal "style_rule", rule.underscored_type
      assert_equal "media_rule", root.rules.last.underscored_type
    end

    test "names everything else after its type" do
      pseudo = root.every("pseudo-class").first

      refute_predicate pseudo, :rule?
      assert_equal "pseudo_class", pseudo.underscored_type
    end

    test "names the nodes Lightning CSS gives no type from where they sit" do
      block = root.rules.first.value.declarations

      assert_equal "declaration-block", block.type
      assert_equal "declaration", block.declarations.first.type
    end

    test "has no type when neither it nor where it sits says one" do
      assert_nil root.rules.first.value.type
      assert_nil root.rules.first.value.underscored_type
    end

    test "walks everything under it" do
      types = root.each.map(&:type)

      assert_equal "stylesheet", types.first
      assert_includes types, "rgb"
    end

    test "answers every node of one type, by its type or its visitor name" do
      assert_equal(["card", "title", "a"], root.every("class").map(&:name))
      assert_equal(["color", "margin", "custom"], root.every("declaration").map(&:property))
      assert_equal 2, root.every("style_rule").length
    end

    test "walks into selectors, which are lists of lists" do
      assert_equal ["class", "combinator", "class", "pseudo-class"], root.rules.first.value.selectors.first.map(&:type)
    end

    test "reads a field as the node it holds" do
      color = root.every("declaration").first

      assert_equal "rgb", color.value.type
      assert_in_delta 255.0, color.value.r
      assert_equal "color", color["property"]
    end

    test "reads a camelCase field by its snake_case name" do
      block = root.rules.first.value.declarations

      assert_empty block.important_declarations
      assert_respond_to block, :important_declarations
      assert_equal ["all"], root.rules.last.value.query.media_queries.map(&:media_type)
    end

    test "raises for a field it does not have" do
      assert_raises(NoMethodError) { root.nonsense }
      refute_respond_to root, :nonsense
    end

    test "answers where a rule starts as Lightning CSS reports it" do
      assert_equal({ "source_index" => 0, "line" => 1, "column" => 29 }, root.rules.last.value.rules.first.value.location)
      assert_nil root.location
    end

    test "does not walk into a location" do
      refute(root.each.any? { |node| node.keys.include?("source_index") })
    end

    test "knows what it sits inside" do
      declaration = root.every("declaration").last

      assert_equal ["declaration-block", nil, "style", nil, "media", "stylesheet"], declaration.ancestors.map(&:type)
      assert_equal "declarations", declaration.field
    end

    test "answers its fields without its type or location" do
      assert_equal ["selectors", "declarations", "rules"], root.rules.first.value.fields.keys
    end

    test "pattern matches, nesting through the nodes it holds" do
      matched = root.every("declaration").find do |node|
        node in { type: "declaration", property: "color", value: { type: "rgb", r: 255.0 } }
      end

      refute_nil matched
    end

    test "pattern matches by snake_case name" do
      root.rules.first.value.declarations => { important_declarations: }

      assert_empty important_declarations
    end

    test "answers its type in a pattern with no keys" do
      assert_equal "declaration", root.every("declaration").first.deconstruct_keys(nil)[:type]
    end

    test "answers the AST it wraps" do
      color = root.every("rgb").first

      assert_equal({ "type" => "rgb", "r" => 255.0, "g" => 0.0, "b" => 0.0, "alpha" => 1.0 }, color.to_h)
      assert_equal color.to_h.to_json, color.to_json
      assert_equal color.to_h.to_json, JSON.generate(color)
    end

    test "prints every field it carries" do
      assert_equal "#<LightningCSS::Node style value=#<LightningCSS::Node>>", root.rules.first.inspect
      assert_equal "#<LightningCSS::Node location=0:1 selectors=[... 1 item] declarations=#<LightningCSS::Node declaration-block> rules=[]>", root.rules.first.value.inspect
      assert_equal "#<LightningCSS::Node declaration property=\"color\" value=#<LightningCSS::Node rgb>>", root.every("declaration").first.inspect
    end
  end
end
