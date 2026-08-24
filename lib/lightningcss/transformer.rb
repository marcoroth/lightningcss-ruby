# frozen_string_literal: true

module LightningCSS
  # A set of options to transform many stylesheets with.
  #
  #     transformer = LightningCSS::Transformer.new(minify: true, targets: { chrome: 100 })
  #
  #     transformer.transform(".a { color: red }").code
  #     transformer.transform(".b { color: red }", scope: "[data-scope-abc]").code
  #
  # Options given to a call are merged over the ones it was built with, so the ones that belong to
  # the project are written once and the ones that belong to a single stylesheet travel with it.
  #
  class Transformer
    attr_reader :options #: Hash[Symbol, untyped]

    #: (?filename: String?, ?minify: bool, ?error_recovery: bool, ?targets: browsers?, ?css_modules: css_modules?, ?scope: String?) -> void
    def initialize(**options)
      @options = options.transform_keys(&:to_sym).freeze

      freeze
    end

    #: (String, ?filename: String?, ?minify: bool, ?error_recovery: bool, ?targets: browsers?, ?css_modules: css_modules?, ?scope: String?) -> LightningCSS::Result
    def transform(code, **overrides)
      LightningCSS.transform(code, **options, **overrides)
    end

    alias call transform

    #: (String, ?filename: String?, ?minify: bool, ?error_recovery: bool, ?targets: browsers?, ?css_modules: css_modules?, ?scope: String?) -> LightningCSS::Result
    def bundle(path, **overrides)
      LightningCSS.bundle(path, **options, **overrides)
    end

    #: (String, ?filename: String?, ?minify: bool, ?error_recovery: bool, ?targets: browsers?) -> LightningCSS::Result
    def transform_style_attribute(code, **overrides)
      LightningCSS.transform_style_attribute(code, **options, **overrides)
    end

    #: (String, ?filename: String?, ?error_recovery: bool, ?targets: browsers?, ?css_modules: css_modules?, ?scope: String?) -> String
    def minify(code, **overrides)
      transform(code, **overrides, minify: true).code
    end

    #: (?filename: String?, ?minify: bool, ?error_recovery: bool, ?targets: browsers?, ?css_modules: css_modules?, ?scope: String?) -> LightningCSS::Transformer
    def with(**overrides)
      self.class.new(**options, **overrides)
    end

    #: () -> String
    def inspect
      "#<#{self.class.name} #{options.inspect}>"
    end
  end
end
