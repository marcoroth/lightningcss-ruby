# frozen_string_literal: true

module LightningCSS
  # One object in the AST Lightning CSS parsed a stylesheet to.
  #
  #     root = LightningCSS.parse(".a { color: red }").root
  #
  #     root.type                        #=> "stylesheet"
  #     root.every("declaration")        #=> every declaration in the stylesheet
  #     root.rules.first.value.location  #=> {"source_index" => 0, "line" => 0, "column" => 1}
  #
  # Every object in the tree is a node, so reads chain all the way down. Most say what they are
  # with their own `type`. The stylesheet, a declaration block, and a declaration do not, so a node
  # names those from where it sits.
  #
  class Node
    include Enumerable #[LightningCSS::Node]

    POSITION = ["type", "loc"].freeze #: Array[String]
    DECLARATIONS = ["declarations", "importantDeclarations"].freeze #: Array[String]

    attr_reader :parent #: LightningCSS::Node?
    attr_reader :field #: String?

    #: (Hash[String, untyped], ?LightningCSS::Node?, ?String?) -> void
    def initialize(attributes, parent = nil, field = nil)
      @attributes = attributes
      @parent = parent
      @field = field
    end

    #: () -> String?
    def type
      attributes.fetch("type") { inferred_type }
    end

    #: () -> String?
    def underscored_type
      return nil unless (name = type)

      name = name.tr("-", "_").downcase

      rule? ? "#{name}_rule" : name
    end

    #: () -> bool
    def rule?
      field == "rules" && attributes.key?("type")
    end

    #: () -> Hash[String, Integer]?
    def location
      attributes["loc"]
    end

    #: (String) -> untyped
    def [](key)
      attributes[key]
    end

    #: () -> Array[String]
    def keys
      attributes.keys
    end

    #: () -> Hash[String, untyped]
    def to_h
      attributes
    end

    #: (?untyped) -> String
    def to_json(state = nil)
      state ? attributes.to_json(state) : attributes.to_json
    end

    #: (Array[Symbol]?) -> Hash[Symbol, untyped]
    def deconstruct_keys(keys)
      found = {} #: Hash[Symbol, untyped]

      if keys
        keys.each do |name|
          key = field_for(name.to_s)

          if key
            found[name] = wrap(attributes[key], key)
          elsif name == :type && type
            found[name] = type
          end
        end
      else
        found[:type] = type if type
        attributes.each_key { |key| found[key.to_sym] = wrap(attributes[key], key) }
      end

      found
    end

    #: () -> Array[LightningCSS::Node]
    def child_nodes
      @child_nodes ||= attributes.flat_map { |key, value| key == "loc" ? [] : nodes_in(value, key) }.freeze
    end

    #: () { (LightningCSS::Node) -> void } -> void
    #: () -> Enumerator[LightningCSS::Node, void]
    def each(&)
      return enum_for(:each) unless block_given?

      yield self

      child_nodes.each { |child| child.each(&) }
    end

    #: () -> Array[LightningCSS::Node]
    def ancestors
      parent ? [parent, *parent.ancestors] : []
    end

    #: (String) -> Array[LightningCSS::Node]
    def every(type)
      each.select { |node| node.type == type || node.underscored_type == type }
    end

    #: () -> Hash[String, untyped]
    def fields
      attributes.except(*POSITION)
    end

    #: () -> String
    def inspect
      described = fields.map { |key, value| described_field(key, value) }
      position = location
      described.unshift("location=#{position["line"]}:#{position["column"]}") if position

      "#<#{self.class.name}#{" #{type}" if type}#{" #{described.join(" ")}" unless described.empty?}>"
    end

    #: (Symbol, *untyped) -> untyped
    def method_missing(name, *arguments)
      key = field_for(name.to_s)

      return super unless key

      wrap(attributes[key], key)
    end

    #: (Symbol, ?bool) -> bool
    def respond_to_missing?(name, include_private = false)
      !field_for(name.to_s).nil? || super
    end

    protected

    attr_reader :attributes #: Hash[String, untyped]

    private

    #: () -> String?
    def inferred_type
      if parent.nil? && attributes.key?("rules") && attributes.key?("sources")
        "stylesheet"
      elsif attributes.key?("importantDeclarations")
        "declaration-block"
      elsif DECLARATIONS.include?(field) && attributes.key?("property")
        "declaration"
      end
    end

    #: (untyped, String) -> Array[LightningCSS::Node]
    def nodes_in(value, key)
      case value
      when Hash then [Node.new(value, self, key)]
      when Array then value.flat_map { |item| nodes_in(item, key) }
      else []
      end
    end

    #: (String, untyped) -> String
    def described_field(key, value)
      case value
      when Array
        "#{key}=#{value.empty? ? "[]" : "[... #{counted(value)}]"}"
      when Hash
        type = Node.new(value, self, key).type

        "#{key}=#<#{self.class.name}#{" #{type}" if type}>"
      else
        "#{key}=#{value.inspect}"
      end
    end

    #: (Array[untyped]) -> String
    def counted(items)
      "#{items.length} #{items.length == 1 ? "item" : "items"}"
    end

    #: (String) -> String?
    def field_for(name)
      return name if attributes.key?(name)

      camelized = name.gsub(/_([a-z\d])/) { Regexp.last_match(1).to_s.upcase }

      camelized if attributes.key?(camelized)
    end

    #: (untyped, String) -> untyped
    def wrap(value, key)
      case value
      when Hash then key == "loc" ? value : Node.new(value, self, key)
      when Array then value.map { |item| wrap(item, key) }
      else value
      end
    end
  end
end
