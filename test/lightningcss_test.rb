# frozen_string_literal: true

require "test_helper"

class LightningCSSTest < Minitest::Spec
  test "has a version number" do
    assert_equal "1.33.0", LightningCSS::VERSION
  end

  test "the native library was built from the version the gem was" do
    assert_equal LightningCSS::VERSION, LightningCSS::Backend.version
  end

  test "reports the version of Lightning CSS it was compiled against" do
    assert_equal "1.0.0-alpha.72", LightningCSS.lightningcss_version
  end

  test "the version it reports is the one Cargo.lock pins" do
    locked = File.read(File.expand_path("../rust/Cargo.lock", __dir__))[/name = "lightningcss"\nversion = "([^"]+)"/, 1]

    assert_equal locked, LightningCSS.lightningcss_version
  end
end
