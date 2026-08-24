# frozen_string_literal: true

require "test_helper"

class LightningCSSTest < Minitest::Spec
  test "has a version number" do
    refute_nil LightningCSS::VERSION
  end
end
