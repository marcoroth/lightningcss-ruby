# frozen_string_literal: true

require "test_helper"

module LightningCSS
  class ErrorsTest < Minitest::Spec
    test "raises on CSS it cannot parse" do
      error = assert_raises(LightningCSS::ParseError) { LightningCSS.transform(". { color: red }") }

      assert_equal 'Expected identifier in class selector, got WhiteSpace(" ") at :0:2', error.message
    end

    test "says where it could not parse" do
      error = assert_raises(LightningCSS::ParseError) { LightningCSS.transform("!!! { color: red }") }

      assert_equal "Invalid empty selector at :0:1", error.message
    end

    test "closes an unclosed block the way a browser does" do
      assert_equal ".a{color:red}", LightningCSS.transform(".a { color: red", minify: true).code
    end

    test "carries on through a broken rule when told to recover" do
      code = LightningCSS.transform("!!! {} .a { color: red }", error_recovery: true, minify: true).code

      assert_equal ".a{color:red}", code
    end

    test "refuses an option it does not know" do
      error = assert_raises(LightningCSS::OptionError) { LightningCSS.transform(".a {}", nonsense: true) }

      assert_equal "Unknown option: nonsense", error.message
    end

    test "names every option it does not know" do
      error = assert_raises(LightningCSS::OptionError) { LightningCSS.transform(".a {}", nope: 1, nah: 2) }

      assert_equal "Unknown options: nope, nah", error.message
    end

    test "every error it raises is an error" do
      assert_operator LightningCSS::ParseError, :<, LightningCSS::Error
      assert_operator LightningCSS::OptionError, :<, LightningCSS::Error
      assert_operator LightningCSS::BundleError, :<, LightningCSS::Error
      assert_operator LightningCSS::Error, :<, StandardError
    end
  end
end
