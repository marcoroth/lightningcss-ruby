# frozen_string_literal: true

module LightningCSS
  # What a stylesheet parsed to.
  #
  # `stylesheet` is the AST exactly as Lightning CSS serializes it, and `root` is the same tree as a
  # `LightningCSS::Node` to walk. `warnings` are the ones a transform would have reported.
  #
  class ParseResult
    attr_reader :source #: String?
    attr_reader :stylesheet #: Hash[String, untyped]
    attr_reader :warnings #: Array[String]

    #: (String, ?String?) -> LightningCSS::ParseResult
    def self.from_json(payload, source = nil)
      parsed = JSON.parse(payload)

      new(
        source: source,
        stylesheet: parsed.fetch("stylesheet"),
        warnings: parsed.fetch("warnings")
      )
    end

    #: (stylesheet: Hash[String, untyped], warnings: Array[String], ?source: String?) -> void
    def initialize(stylesheet:, warnings:, source: nil)
      @source = source
      @stylesheet = stylesheet.freeze
      @warnings = warnings.freeze

      freeze
    end

    #: () -> LightningCSS::Node
    def root
      Node.new(stylesheet)
    end

    #: () -> bool
    def warnings?
      !warnings.empty?
    end

    #: () -> String
    def inspect
      parts = ["rules=#{stylesheet.fetch("rules").length}"]
      parts << "warnings=#{warnings.inspect}" if warnings?

      "#<#{self.class.name} #{parts.join(" ")}>"
    end
  end
end
