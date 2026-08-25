# frozen_string_literal: true

require "test_helper"

module LightningCSS
  class ThreadsTest < Minitest::Spec
    STYLESHEET = (1..50_000).map { |i| ".c#{i} { color: #ff0000; padding: #{i % 40}px }" }.join("\n")

    test "lets another thread run while the native library works" do
      ticks = 0
      running = true

      worker = Thread.new { ticks += 1 while running }

      sleep 0.05

      before = ticks
      LightningCSS.transform(STYLESHEET, minify: true)
      during = ticks - before

      running = false
      worker.join

      assert_operator during, :>, 0
    end
  end
end
