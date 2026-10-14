# frozen_string_literal: true

module LightningCSS
  Location = Data.define(
    :filename, #: String?
    :line, #: Integer
    :column #: Integer
  )

  class Location
    #: (Hash[String, untyped]) -> LightningCSS::Location
    def self.from_hash(hash)
      new(filename: hash["filename"], line: hash.fetch("line"), column: hash.fetch("column"))
    end

    #: () -> String
    def to_s
      "#{filename}:#{line}:#{column + 1}"
    end
  end
end
