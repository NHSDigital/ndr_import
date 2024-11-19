require 'test_helper'

# Tests the legacy CSVLibrary class
class CSVLibraryTest < ActiveSupport::TestCase
  test 'is distinct from the standard library CSV' do
    refute_equal CSV, CSVLibrary
  end

  test 'interits from the standard library CSV' do
    assert CSVLibrary < CSV
  end

  test 'raises deprecation warnings' do
    deprecator = CSVLibrary.send(:deprecator)
    assert_deprecated(/will be removed in a future version of ndr_import/, deprecator) do
      assert CSVLibrary.fastercsv?, '::CSV unexpectedly was the _old_ standard library'
    end
  end

  test 'defines functional legacy methods' do
    deprecator = CSVLibrary.send(:deprecator)
    assert_deprecated(/write_csv_to_string -> generate/, deprecator) do
      assert_equal "1,2,3\n", CSVLibrary.write_csv_to_string([%w[1 2 3]])
    end
  end
end
