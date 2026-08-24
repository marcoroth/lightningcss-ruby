# frozen_string_literal: true

module LightningCSS
  class Error < StandardError; end
  class ParseError < Error; end
  class OptionError < Error; end
  class BundleError < Error; end
end
