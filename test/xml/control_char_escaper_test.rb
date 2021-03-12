require 'test_helper'

# This tests the NdrImport::Xml::Table mapping class
module Xml
  class ControlCharEscaperTest < ActiveSupport::TestCase
    def test_should_escape_in_place
      data = "test \x1c data"
      escape(data)

      assert_equal data, 'test 0x1c data'
    end

    def test_should_escape_control_character
      assert_equal 'hello 0x00 world', escape("hello \x00 world")
    end

    def test_should_escape_decimal_control_character_reference
      assert_equal 'hello 0x00 world', escape('hello &#00; world')
      assert_equal 'hello 0x1c world', escape('hello &#28; world')
    end

    def test_should_escape_hexadecimal_control_character_reference
      assert_equal 'hello 0x00 world', escape('hello &#x00; world')
      assert_equal 'hello 0x1c world', escape('hello &#x1C; world')
    end

    def test_should_not_escape_non_control_character_decimal_reference
      assert_equal 'hell&#111; world', escape('hell&#111; world')
    end

    def test_should_gracefully_handle_nonsense_decimal_input
      assert_equal '&#0123456789;', escape('&#0123456789;')
    end

    def test_should_not_escape_non_control_character_hexadecimal_reference
      assert_equal 'hell&#x6F; world', escape('hell&#x6F; world')
    end

    def test_should_gracefully_handle_nonsense_hexadecimal_input
      assert_equal '&#xABCDEF0123456789;', escape('&#xABCDEF0123456789;')
    end

    private

    def escape(data)
      NdrImport::Xml::ControlCharEscaper.new(data).escape!
      data
    end
  end
end
