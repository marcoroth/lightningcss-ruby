# frozen_string_literal: true

require "test_helper"

module LightningCSS
  class LocationTest < Minitest::Spec
    test "prints as a filename, a line, and a column counted from 1" do
      assert_equal "main.css:2:5", Location.new(filename: "main.css", line: 2, column: 4).to_s
    end

    test "prints without a filename when it has none" do
      assert_equal ":1:1", Location.new(filename: nil, line: 1, column: 0).to_s
    end

    test "is equal to a location with the same fields" do
      assert_equal Location.new(filename: "a.css", line: 1, column: 0), Location.new(filename: "a.css", line: 1, column: 0)
    end

    test "is frozen" do
      assert_predicate Location.new(filename: "a.css", line: 1, column: 0), :frozen?
    end
  end
end
