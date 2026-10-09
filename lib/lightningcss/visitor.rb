# frozen_string_literal: true

module LightningCSS
  # Walks an AST, answering each node with the method named after it and walking through anything
  # nothing answers.
  #
  #     class Colors < LightningCSS::Visitor
  #       def visit_declaration(node)
  #         puts node.value.type if node.property == "color"
  #       end
  #     end
  #
  #     Colors.new.visit(LightningCSS.parse(".a { color: red }"))
  #
  # A rule is answered as one, as in `visit_style_rule` or `visit_media_rule`, since `style`,
  # `nesting`, and `namespace` are also what a selector is made of.
  #
  class Visitor
    #: (LightningCSS::Node | LightningCSS::ParseResult) -> void
    def visit(node)
      node = node.root if node.is_a?(ParseResult)

      answer = "visit_#{node.underscored_type}" if node.underscored_type

      answer && respond_to?(answer) ? public_send(answer, node) : visit_children(node)

      nil
    end

    #: (LightningCSS::Node) -> void
    def visit_children(node)
      node.child_nodes.each { |child| visit(child) }

      nil
    end
  end
end
