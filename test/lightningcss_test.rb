# frozen_string_literal: true

require "test_helper"

class LightningCSSTest < Minitest::Spec
  test "has a version number" do
    assert_equal "0.1.0", LightningCSS::VERSION
  end

  test "the native library was built from the version the gem was" do
    assert_equal LightningCSS::VERSION, LightningCSS.native_version
  end
end
