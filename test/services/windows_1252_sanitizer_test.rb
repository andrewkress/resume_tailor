require "test_helper"

class Windows1252SanitizerTest < ActiveSupport::TestCase
  test "preserves windows 1252 compatible punctuation" do
    text = "• – — ‘ ’ “ ” … ™ © ® résumé"

    assert_equal text, Windows1252Sanitizer.call(text)
  end

  test "replaces unsupported whitespace and symbols" do
    text = "Lead\u00A0Engineer\u2009|\u200B Built features\u2028Shipped fixes \u2212 improved QA \u2713"

    assert_equal "Lead Engineer | Built features\nShipped fixes - improved QA *", Windows1252Sanitizer.call(text)
  end

  test "normalizes unicode hyphen variants instead of dropping them" do
    text = "customer\u2010facing customer\u2011facing customer\u2012facing"

    assert_equal "customer-facing customer-facing customer-facing", Windows1252Sanitizer.call(text)
  end

  test "removes unsupported emoji" do
    text = "Growth \u{1F4C8} across products"

    assert_equal "Growth  across products", Windows1252Sanitizer.call(text)
  end
end
