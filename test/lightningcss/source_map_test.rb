# frozen_string_literal: true

require "test_helper"

module LightningCSS
  class SourceMapTest < Minitest::Spec
    CSS = ".a {\n  user-select: none;\n}\n\n.b {\n  color: red;\n}\n"
    SCSS = "$c: red;\n.a { user-select: none; }\n.b { color: $c; }\n"
    ENTRY = File.expand_path("../fixtures/bundle/entry.css", __dir__)
    ROOT = File.expand_path("../fixtures/bundle", __dir__)

    INPUT = JSON.generate(
      version: 3,
      file: "main.css",
      sources: ["app.scss"],
      names: [],
      sourcesContent: [SCSS],
      mappings: "AACA;EAAI;;;AACJ;EAAI"
    )

    def map_of(css = CSS, **)
      JSON.parse(LightningCSS.transform(css, filename: "main.css", source_map: true, minify: true, **).map)
    end

    test "has no map when it was not asked for one" do
      assert_nil LightningCSS.transform(CSS, filename: "main.css").map
    end

    test "answers a map as a JSON string" do
      assert_instance_of String, LightningCSS.transform(CSS, filename: "main.css", source_map: true).map
    end

    test "maps the output back to the stylesheet it was given" do
      map = map_of

      assert_equal 3, map["version"]
      assert_equal "AAAA,oBAIA", map["mappings"]
      assert_equal ["main.css"], map["sources"]
      assert_equal [CSS], map["sourcesContent"]
    end

    test "chains through an input source map" do
      map = map_of(input_source_map: INPUT)

      assert_equal "ACCA,oBACA", map["mappings"]
      assert_equal ["main.css", "app.scss"], map["sources"]
      assert_equal [CSS, SCSS], map["sourcesContent"]
    end

    test "writes sources relative to the project root" do
      map = JSON.parse(LightningCSS.transform(CSS, filename: "/app/css/main.css", source_map: true, project_root: "/app").map)

      assert_equal ["css/main.css"], map["sources"]
    end

    test "raises an option error for an input source map that is not JSON" do
      error = assert_raises(OptionError) { LightningCSS.transform(CSS, source_map: true, input_source_map: "nope") }

      assert_match(/\AInvalid input source map: /, error.message)
    end

    test "raises an option error for an input source map with broken mappings" do
      input = JSON.generate(version: 3, sources: [], names: [], mappings: "!!!")
      error = assert_raises(OptionError) { LightningCSS.transform(CSS, source_map: true, input_source_map: input) }

      assert_match(/\AInvalid input source map: /, error.message)
    end

    test "raises an option error for an input source map it was not asked to chain" do
      error = assert_raises(OptionError) { LightningCSS.transform(CSS, input_source_map: INPUT) }

      assert_equal "input_source_map needs source_map: true", error.message
    end

    test "adds every file a bundle read to its sources, with its contents" do
      map = JSON.parse(LightningCSS.bundle(ENTRY, source_map: true, project_root: ROOT).map)
      contents = map["sources"].zip(map["sourcesContent"]).to_h

      assert_equal ["colors.css", "entry.css", "nested/layout.css"], contents.keys.sort
      contents.each { |source, content| assert_equal File.read(File.join(ROOT, source)), content }
    end

    test "has no map for a bundle that was not asked for one" do
      assert_nil LightningCSS.bundle(ENTRY).map
    end

    test "refuses an input source map for a bundle" do
      error = assert_raises(OptionError) { LightningCSS.bundle(ENTRY, source_map: true, input_source_map: INPUT) }

      assert_equal "input_source_map is not an option for a bundle", error.message
    end

    test "refuses a source map for a style attribute" do
      error = assert_raises(OptionError) { LightningCSS.transform_style_attribute("color: red", source_map: true) }

      assert_equal "source_map is not an option for a style attribute", error.message
    end

    test "a transformer carries its source map options" do
      map = JSON.parse(Transformer.new(filename: "main.css", source_map: true).transform(CSS).map)

      assert_equal ["main.css"], map["sources"]
    end
  end
end
