# frozen_string_literal: true

module LightningCSS
  # What a transform produced.
  #
  # `exports` is only filled in when the stylesheet was compiled as a CSS module, and maps every
  # name as it was written to the name it was compiled to. A transform that was not asked for a
  # CSS module has none, and neither does a style attribute, which has no names to compile.
  #
  # `warnings` holds what Lightning CSS understood well enough to keep but not well enough to act
  # on, which is everything it would otherwise have dropped without saying so.
  #
  class Result
    attr_reader :code #: String
    attr_reader :exports #: Hash[String, String]?
    attr_reader :warnings #: Array[String]

    #: (String) -> LightningCSS::Result
    def self.from_json(payload)
      parsed = JSON.parse(payload)

      new(
        code: parsed.fetch("code"),
        exports: parsed["exports"],
        warnings: parsed.fetch("warnings")
      )
    end

    #: (code: String, warnings: Array[String], ?exports: Hash[String, String]?) -> void
    def initialize(code:, warnings:, exports: nil)
      @code = code
      @exports = exports
      @warnings = warnings.freeze

      freeze
    end

    #: () -> bool
    def warnings?
      !warnings.empty?
    end

    #: () -> String
    def to_s
      code
    end

    #: () -> String
    def inspect
      parts = ["code=#{code.inspect}"]
      parts << "exports=#{exports.inspect}" if exports
      parts << "warnings=#{warnings.inspect}" if warnings?

      "#<#{self.class.name} #{parts.join(" ")}>"
    end
  end
end
