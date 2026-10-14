# frozen_string_literal: true

module LightningCSS
  class Warning
    attr_reader :message #: String
    attr_reader :type #: String?
    attr_reader :location #: LightningCSS::Location?

    #: (Hash[String, untyped]) -> LightningCSS::Warning
    def self.from_hash(hash)
      new(
        message: hash.fetch("message"),
        type: hash["type"],
        location: hash["location"] && Location.from_hash(hash["location"])
      )
    end

    #: (message: String, ?type: String?, ?location: LightningCSS::Location?) -> void
    def initialize(message:, type: nil, location: nil)
      @message = message
      @type = type
      @location = location

      freeze
    end

    #: () -> Hash[Symbol, untyped]
    def to_h
      { message: message, type: type, location: location&.to_h }
    end

    #: () -> String
    def to_s
      location ? "#{message} at #{location}" : message
    end

    alias to_str to_s

    #: (untyped) -> bool
    def ==(other)
      case other
      when Warning then to_h == other.to_h
      when String then to_s == other
      else false
      end
    end

    alias eql? ==

    #: () -> Integer
    def hash
      to_h.hash
    end

    #: () -> String
    def inspect
      "#<#{self.class.name} #{to_s.inspect}>"
    end
  end
end
