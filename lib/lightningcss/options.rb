# frozen_string_literal: true

module LightningCSS
  # The options a call was given, on their way to the native library.
  #
  # Lightning CSS reads them as JSON, so this is where a Ruby hash becomes one, and where an option
  # nobody knows is refused. Refusing early is the point: an option the native side does not read
  # would otherwise be accepted and quietly do nothing.
  #
  #     LightningCSS::Options.new(minify: true).to_json  #=> "{\"minify\":true}"
  #
  class Options
    KNOWN = [
      :filename,
      :minify,
      :error_recovery,
      :targets,
      :css_modules,
      :scope
    ].freeze #: Array[Symbol]

    STYLE_ATTRIBUTE = [
      :filename,
      :minify,
      :error_recovery,
      :targets
    ].freeze #: Array[Symbol]

    attr_reader :to_h #: Hash[Symbol, untyped]

    #: (Hash[Symbol, untyped], ?allowed: Array[Symbol], ?subject: String) -> String
    def self.serialize(options, allowed: KNOWN, subject: "a transform")
      new(allowed: allowed, subject: subject, **options).to_json
    end

    #: (?allowed: Array[Symbol], ?subject: String, **untyped) -> void
    def initialize(allowed: KNOWN, subject: "a transform", **options)
      given = options.transform_keys(&:to_sym)

      validate!(given.keys, allowed, subject)

      @to_h = normalize(given).freeze

      freeze
    end

    #: (?untyped) -> String
    def to_json(state = nil)
      JSON.generate(to_h, state)
    end

    #: () -> String
    def inspect
      "#<#{self.class.name} #{to_h.inspect}>"
    end

    private

    #: (Array[Symbol], Array[Symbol], String) -> void
    def validate!(names, allowed, subject)
      unknown = names - KNOWN

      raise OptionError, "Unknown option#{"s" if unknown.length > 1}: #{unknown.join(", ")}" if unknown.any?

      unsupported = names - allowed

      return if unsupported.empty?

      raise OptionError, "#{unsupported.join(", ")} #{unsupported.one? ? "is not an option" : "are not options"} for #{subject}"
    end

    #: (Hash[Symbol, untyped]) -> Hash[Symbol, untyped]
    def normalize(options)
      normalized = options.dup

      normalized[:css_modules] = {} if normalized[:css_modules] == true
      normalized.delete(:css_modules) if normalized[:css_modules] == false

      normalized.compact
    end
  end
end
