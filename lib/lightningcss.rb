# frozen_string_literal: true

require "json"

require_relative "lightningcss/version"
require_relative "lightningcss/errors"
require_relative "lightningcss/backend"

begin
  major, minor, = RUBY_VERSION.split(".")
  require_relative "lightningcss/#{major}.#{minor}/lightningcss"
rescue LoadError
  require_relative "lightningcss/lightningcss"
end

require_relative "lightningcss/options"
require_relative "lightningcss/result"
require_relative "lightningcss/transformer"

# Ruby bindings for Lightning CSS.
#
#     LightningCSS.transform(".a { color: red }", minify: true).code
#     #=> ".a{color:red}"
#
# Every option is passed through to Lightning CSS as written, except `scope`, which narrows each
# rule by a selector fragment so a stylesheet only applies where that fragment matches:
#
#     LightningCSS.transform(".title { color: red }", scope: "[data-scope-abc]").code
#     #=> ".title[data-scope-abc]{color:red}"
#
# `LightningCSS::Options` is what the options are read by, and `LightningCSS::Transformer` holds a
# set of them to reuse across many stylesheets.
module LightningCSS
  #: (String, ?filename: String?, ?minify: bool, ?error_recovery: bool, ?targets: browsers?, ?css_modules: css_modules?, ?scope: String?) -> LightningCSS::Result
  def self.transform(code, **options)
    Result.from_json(Backend.transform(code.to_s, Options.serialize(options)))
  end

  #: (String, ?filename: String?, ?minify: bool, ?error_recovery: bool, ?targets: browsers?, ?css_modules: css_modules?, ?scope: String?) -> LightningCSS::Result
  def self.bundle(path, **options)
    Result.from_json(Backend.bundle(path.to_s, Options.serialize(options)))
  end

  #: (String, ?filename: String?, ?minify: bool, ?error_recovery: bool, ?targets: browsers?) -> LightningCSS::Result
  def self.transform_style_attribute(code, **options)
    serialized = Options.serialize(options, allowed: Options::STYLE_ATTRIBUTE, subject: "a style attribute")

    Result.from_json(Backend.transform_style_attribute(code.to_s, serialized))
  end

  #: (String, ?filename: String?, ?error_recovery: bool, ?targets: browsers?, ?css_modules: css_modules?, ?scope: String?) -> String
  def self.minify(code, **)
    transform(code, **, minify: true).code
  end

  #: () -> String
  def self.lightningcss_version
    Backend.lightningcss_version
  end
end
