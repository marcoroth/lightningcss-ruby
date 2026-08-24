# frozen_string_literal: true

require "test_helper"

module LightningCSS
  class ScopeTest < Minitest::Spec
    def scoped(source, fragment = "[s]")
      LightningCSS.transform(source, scope: fragment, minify: true).code
    end

    test "narrows every rule by the fragment it was given" do
      source = ".title { color: red }\n.card .title { font-weight: bold }"

      assert_equal ".title[s]{color:red}.card .title[s]{font-weight:700}", scoped(source)
    end

    test "narrows the last compound, so a pseudo element stays last" do
      assert_equal '.item[s]:before{content:"x"}', scoped(".item::before { content: 'x' }")
    end

    test "narrows every selector in a list" do
      assert_equal "a[s],.b .c[s]{color:red}", scoped("a, .b .c { color: red }")
    end

    test "narrows the compound a combinator ends on" do
      assert_equal ".a>.b+.c[s]{color:red}", scoped(".a > .b + .c { color: red }")
    end

    test "takes a fragment carrying its own alternatives" do
      code = scoped(".title { color: red }", ":where([s], [s] *)")

      assert_equal ".title:where([s],[s] *){color:red}", code
    end

    test "leaves keyframe selectors alone" do
      source = "@keyframes spin { from { opacity: 0 } to { opacity: 1 } }"

      assert_equal "@keyframes spin{0%{opacity:0}to{opacity:1}}", scoped(source)
    end

    test "leaves the inside of a functional pseudo class alone" do
      assert_equal ".x:not(.y)[s]{color:red}", scoped(".x:not(.y) { color: red }")
      assert_equal ".p:is(.q,.r)[s]{color:red}", scoped(".p:is(.q, .r) { color: red }")
    end

    test "narrows a rule nested in an at-rule" do
      source = "@media (min-width: 40rem) { .a { color: red } }"

      assert_equal "@media (width>=40rem){.a[s]{color:red}}", scoped(source)
    end

    test "narrows the universal selector down to the fragment alone" do
      assert_equal "[s]{color:red}", scoped("* { color: red }")
    end

    test "narrows a document level selector too, where it can never match" do
      assert_equal ":root[s]{--gap:1rem}", scoped(":root { --gap: 1rem }")
    end

    test "refuses a fragment that is not a selector" do
      error = assert_raises(LightningCSS::OptionError) { scoped(".a { color: red }", "((") }

      assert_equal 'Invalid scope selector "((" at :0:1', error.message
    end

    test "refuses a fragment carrying more than one selector" do
      error = assert_raises(LightningCSS::OptionError) { scoped(".a { color: red }", "[a], [b]") }

      assert_equal %(Scope selector "[a], [b]" has to be a single selector), error.message
    end
  end
end
