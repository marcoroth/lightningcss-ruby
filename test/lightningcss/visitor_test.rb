# frozen_string_literal: true

require "test_helper"

module LightningCSS
  class VisitorTest < Minitest::Spec
    SOURCE = ".a { color: red }\n@media print { .b { color: blue; &.c { margin: 0 } } }"

    class Collector < Visitor
      attr_reader :seen #: Array[String]

      def initialize
        @seen = []

        super
      end

      def visit_media_rule(node)
        seen << "media"

        visit_children(node)
      end

      def visit_declaration(node)
        seen << node.property
      end

      def visit_nesting(_node)
        seen << "&"
      end
    end

    test "answers a node with the method named after it" do
      collector = Collector.new
      collector.visit(LightningCSS.parse(SOURCE).root)

      assert_equal ["color", "media", "color", "&", "margin"], collector.seen
    end

    test "takes a parse result and walks from its root" do
      collector = Collector.new
      collector.visit(LightningCSS.parse(SOURCE))

      assert_equal ["color", "media", "color", "&", "margin"], collector.seen
    end

    test "answers a rule as a rule and a selector as a selector" do
      seen = []

      visitor = Class.new(Visitor) do
        define_method(:visit_namespace_rule) { |node| seen << "rule #{node.value.prefix}" }
        define_method(:visit_namespace) { |node| seen << "selector #{node.prefix}" }
      end

      visitor.new.visit(LightningCSS.parse("@namespace svg url(http://www.w3.org/2000/svg);\nsvg|rect { color: red }"))

      assert_equal ["rule svg", "selector svg"], seen
    end

    test "does not walk under a node it answers unless asked to" do
      seen = []

      visitor = Class.new(Visitor) do
        define_method(:visit_media_rule) { |_node| seen << "media" }
        define_method(:visit_declaration) { |node| seen << node.property }
      end

      visitor.new.visit(LightningCSS.parse(SOURCE))

      assert_equal ["color", "media"], seen
    end

    test "answers nothing" do
      assert_nil Collector.new.visit(LightningCSS.parse(SOURCE))
    end
  end
end
