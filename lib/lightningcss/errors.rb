# frozen_string_literal: true

module LightningCSS
  class Error < StandardError
    attr_reader :type #: String?
    attr_reader :location #: LightningCSS::Location?

    #: (String) -> instance
    def self.from_json(payload)
      parsed = JSON.parse(payload)
      location = parsed["location"] && Location.from_hash(parsed["location"])
      message = parsed.fetch("message")

      new(location ? "#{message} at #{location}" : message, type: parsed["type"], location: location)
    end

    #: (?String?, ?type: String?, ?location: LightningCSS::Location?) -> void
    def initialize(message = nil, type: nil, location: nil)
      super(message)

      @type = type
      @location = location
    end
  end

  class ParseError < Error; end
  class OptionError < Error; end
  class BundleError < Error; end
end
