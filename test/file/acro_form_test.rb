require 'test_helper'
require 'ndr_import/file/acro_form'

module NdrImport
  module File
    # Acro Form file handler tests
    class AcroFormTest < ActiveSupport::TestCase
      def setup
        @permanent_test_files = SafePath.new('permanent_test_files')
      end

      test 'should read pdf correctly' do
        file_path = @permanent_test_files.join('acro_form.pdf')
        handler = NdrImport::File::AcroForm.new(file_path, nil)

        expected_row = { 'Group3'                      => nil,
                         'Textbox1_required'           => nil,
                         'Textbox2_required'           => nil,
                         'List Box_required'           => '3',
                         'Dropdown_required'           => '3',
                         'Textbox1_optional'           => nil,
                         'Textbox2_optional'           => nil,
                         'List Box_optional'           => '3',
                         'Dropdown_optional'           => '3',
                         'Date_required'               => nil,
                         'Date__optional'              => nil,
                         'Textbox3_numerical_required' => nil,
                         'Textbox3_numerical_optional' => nil }

        handler.tables.each do |tablename, sheet|
          assert_nil tablename
          assert_instance_of Enumerator, sheet
          assert_equal 1, sheet.to_a.size
          assert_equal expected_row, sheet.to_a.first
        end
      end
    end
  end
end
