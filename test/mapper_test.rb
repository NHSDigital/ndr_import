require 'test_helper'

# expose private methods
class TestMapper
  include NdrImport::Mapper

  public :fixed_width_columns, :mapped_line, :mapped_value, :replace_before_mapping

  # TODO: test fixed_width_columns
end

# This tests the NdrImport::Mapper class
class MapperTest < ActiveSupport::TestCase
  def setup
    @permanent_test_files = SafePath.new('permanent_test_files')
  end

  format_mapping = { 'format' => 'dd/mm/yyyy' }
  format_mapping_yyyymmdd = { 'format' => 'yyyymmdd' }
  clean_name_mapping = { 'clean' => :name }
  clean_ethniccategory_mapping = { 'clean' => :ethniccategory }
  clean_icd_mapping = { 'clean' => :icd }
  clean_opcs_mapping = { 'clean' => :code_opcs }
  clean_code_and_upcase_mapping = { 'clean' => [:code, :upcase] }
  map_mapping = { 'map' => { 'A' => '1' } }
  replace_mapping = { 'replace' => { '.0' => '' } }
  daysafter_mapping = { 'daysafter' => '2012-05-16' }
  # TODO: match_mapping = {}

  simple_mapping = [{ 'column' => 'patient address', 'mappings' => ['field' => 'address'] }]

  simple_mapping_with_clean_opcs = YAML.load <<-YML
    - column: primaryprocedures
      mappings:
      - field: primaryprocedures
        clean: :code_opcs
  YML

  join_mapping = YAML.load <<-YML
    - column: forename1
      mappings:
      - field: forenames
        order: 1
        join: " "
    - column: forename2
      mappings:
      - field: forenames
        order: 2
  YML

  join_compact_mapping = YAML.load <<-YML
    - column: forename1
      mappings:
      - field: forenames
        order: 1
        join: " "
        compact: false
    - column: forename2
      mappings:
      - field: forenames
        order: 2
  YML

  unused_mapping = [{ 'column' => 'extra', 'rawtext_name' => 'extra' }]

  cross_populate_mapping = YAML.load <<-YML
    - column: referringclinicianname
      mappings:
      - field: consultantname
      - field: consultantcode
        priority: 2
    - column: referringcliniciancode
      mappings:
      - field: consultantcode
  YML

  cross_populate_replace_mapping = YAML.load <<-YML
    - column: referringclinicianname
      mappings:
      - field: consultantname
      - field: consultantcode
        priority: 2
        replace:
          ? !ruby/regexp /^BOB FOSSIL$/i
          : "ROBERT FOSSIL"
    - column: referringcliniciancode
      mappings:
      - field: consultantcode
        priority: 1
  YML

  cross_populate_map_mapping = YAML.load <<-YML
    - column: referringclinicianname
      mappings:
      - field: consultantname
      - field: consultantcode
        priority: 2
        map:
          "Bob Fossil": "C5678"
    - column: referringcliniciancode
      mappings:
      - field: consultantcode
        priority: 1
  YML

  cross_populate_map_reverse_priority_mapping = YAML.load <<-YML
    - column: referringclinicianname
      mappings:
      - field: consultantname
      - field: consultantcode
        priority: 1
        map:
          "Bob Fossil": "C5678"
          "Bolo": ""
    - column: referringcliniciancode
      mappings:
      - field: consultantcode
        priority: 2
  YML

  cross_populate_order_mapping = YAML.load <<-YML
    - column: referringclinicianname
      mappings:
      - field: consultantname
      - field: consultantcode
        priority: 2
    - column: referringcliniciancode
      mappings:
      - field: consultantcode
        priority: 1
    - column: somecolumn
      mappings:
      - field: consultantcode
        priority: 5
    - column: anothercolumn
      mappings:
      - field: consultantcode
        priority: 10
  YML

  cross_populate_no_priority = YAML.load <<-YML
    - column: columnoneraw
      mappings:
      - field: columnone
      - field: columntwo
    - column: columntworaw
      mappings:
      - field: columntwo
        priority: 5
  YML

  standard_mapping_without = YAML.load <<-YML
    - column: surname
      rawtext_name: surname
      mappings:
      - field: surname
        clean: :name
    - column: forename
      rawtext_name: forenames
      mappings:
      - field: forenames
        clean: :name
    - column: sex
      rawtext_name: sex
      mappings:
      - field: sex
        clean: :sex
    - column: nhs_no
      rawtext_name: nhsnumber
      mappings:
      - field: nhsnumber
        clean: :nhsnumber
  YML

  standard_mapping_with = YAML.load <<-YML
    - standard_mapping: surname
    - column: forename
      standard_mapping: forenames
    - standard_mapping: sex
    - column: nhs_no
      standard_mapping: nhsnumber
  YML

  standard_mapping_merge = YAML.load <<-YML
    - column: surname
      standard_mapping: surname
      mappings:
      - field: surname2
  YML

  standard_mapping_column = YAML.load <<-YML
    - column: overriding_column_name
      standard_mapping: test
  YML

  invalid_priorities = YAML.load <<-YML
    - column: columnoneraw
      mappings:
      - field: columnone
      - field: columntwo
        priority: 5
    - column: columntworaw
      mappings:
      - field: columntwo
        priority: 5
  YML

  invalid_standard_mapping = YAML.load <<-YML
    - column: surname
      standard_mapping: surnames
  YML

  joined_mapping_blank_start = YAML.load <<-YML
    - column: addressoneraw
      mappings:
      - field: address
        join: ","
        order: 1
    - column: postcode
      mappings:
      - field: address
        order: 2
  YML

  joined_mapping_blank_start_uncompacted = YAML.load <<-YML
    - column: addressoneraw
      mappings:
      - field: address
        join: ","
        order: 1
        compact: false
    - column: postcode
      mappings:
      - field: address
        order: 2
  YML

  date_mapping = YAML.load <<-YML
    - column: birth_date
      rawtext_name: dateofbirth
      mappings:
      - field: dateofbirth
        format: dd/mm/yyyy
    - column: received_date
      rawtext_name: receiveddate
      mappings:
      - field: receiveddate
        format: yyyymmdd
    - column: american_date
      rawtext_name: americandate
      mappings:
      - field: americandate
        format: mm/dd/yyyy
    - column: short_date
      rawtext_name: shortdate
      mappings:
      - field: shortdate
        format: dd/mm/yy
    - column: funky_date
      rawtext_name: funkydate
      mappings:
      - field: funkydate
        format: dd/mmm/yy
  YML

  do_not_capture_column = YAML.load <<-YML
    - column: ignore_me
      do_not_capture: true
  YML

  base64_mapping = YAML.load <<-YML
    - column: base64
      decode:
      - :base64
      - :word_doc
  YML

  invalid_decode_mapping = YAML.load <<-YML
    - column: column_name
      decode:
      - :invalid_encoding
  YML

  replace_array_mapping = YAML.load <<-YML
    - column: consultantcode
      mappings:
      - field: consultantcode
    - column: hospital
      mappings:
      - field: hospital
        replace:
        - ? !ruby/regexp /Addenbrookes/
          : 'RGT01'
  YML

  validates_presence_mapping = YAML.safe_load <<-YML
    - column: column_one
      mappings:
      - field: field_one
        validates:
          presence: true
    - column: column_two
      mappings:
      - field: field_two
  YML

  test 'map should return a number' do
    assert_equal 'whoops', TestMapper.new.mapped_value('A', map_mapping)
  end

  test 'map should return nil' do
    assert_equal 'B', TestMapper.new.mapped_value('B', map_mapping)
  end

  test 'map should return correct date format' do
    assert_equal Date.new(2011, 1, 25), TestMapper.new.mapped_value('25/01/2011', format_mapping)
    assert_equal Date.new(2011, 1, 25),
                 TestMapper.new.mapped_value('20110125', format_mapping_yyyymmdd)
  end

  test 'map should return incorrect date format' do
    assert_not_equal Date.new(2011, 3, 4),
                     TestMapper.new.mapped_value('03/04/2011', format_mapping)
  end

  test 'map should return nil date format' do
    assert_nil TestMapper.new.mapped_value('03/25/2011', format_mapping)
  end

  test 'map should replace value' do
    value = '2.0'
    TestMapper.new.replace_before_mapping(value, replace_mapping)
    assert_equal '2', value
  end

  test 'map should not alter value' do
    value = '2.1'
    TestMapper.new.replace_before_mapping(value, replace_mapping)
    assert_equal '2.1', value
  end

  test 'map should clean name' do
    assert_equal 'ANNABELLE SMITH',
                 TestMapper.new.mapped_value('anna.belle,smith', clean_name_mapping)
  end

  test 'map should clean ethenic category' do
    assert_equal 'M', TestMapper.new.mapped_value('1', clean_ethniccategory_mapping)
    assert_equal 'X', TestMapper.new.mapped_value('99', clean_ethniccategory_mapping)
    assert_equal 'A', TestMapper.new.mapped_value('A', clean_ethniccategory_mapping)
    assert_equal 'INVALID', TestMapper.new.mapped_value('InValiD', clean_ethniccategory_mapping)
  end

  test 'map should clean icd code' do
    assert_equal 'C343 R932 Z515',
                 TestMapper.new.mapped_value('C34.3,R93.2,Z51.5', clean_icd_mapping)
  end

  test 'map should clean opcs code' do
    assert_equal 'U212 Y973', TestMapper.new.mapped_value('U212,Y973,X1', clean_opcs_mapping)
    assert_equal '', TestMapper.new.mapped_value('98', clean_opcs_mapping)
    assert_equal '', TestMapper.new.mapped_value('TooLong', clean_opcs_mapping)
    assert_nil TestMapper.new.mapped_value('', clean_opcs_mapping)
    assert_equal 'ABCD', TestMapper.new.mapped_value('AbcD', clean_opcs_mapping)
    assert_equal '1234', TestMapper.new.mapped_value('1234', clean_opcs_mapping)
  end

  test 'map should use multiple cleans' do
    assert_equal 'U3 Y2 X1',
                 TestMapper.new.mapped_value('u3,y2,x1', clean_code_and_upcase_mapping)
  end

  test 'map should handle array original value' do
    original_value = ['C9999998', %w(Addenbrookes RGT01)]
    mapped_value = TestMapper.new.mapped_line(original_value, replace_array_mapping)
    assert_equal %w(RGT01 RGT01), mapped_value['hospital']
  end

  test 'should raise an error on blank mandatory field' do
    exception = assert_raise(NdrImport::MissingFieldError) do
      TestMapper.new.mapped_line(['', 'RGT01'], validates_presence_mapping)
    end
    assert_equal "field_one can't be blank", exception.message
  end

  test 'should return correct date format for date fields with daysafter' do
    assert_equal Date.new(2012, 5, 18), TestMapper.new.mapped_value(2, daysafter_mapping)
    assert_equal Date.new(2012, 5, 18), TestMapper.new.mapped_value('2', daysafter_mapping)
    assert_equal Date.new(2012, 5, 14), TestMapper.new.mapped_value(-2, daysafter_mapping)
    assert_equal Date.new(2012, 5, 14), TestMapper.new.mapped_value('-2', daysafter_mapping)
    assert_equal Date.new(2012, 5, 16), TestMapper.new.mapped_value(0, daysafter_mapping)
    assert_equal 'String', TestMapper.new.mapped_value('String', daysafter_mapping)
    assert_equal '', TestMapper.new.mapped_value('', daysafter_mapping)
    assert_nil TestMapper.new.mapped_value(nil, daysafter_mapping)
    assert_equal Date.new(2057, 8, 23), TestMapper.new.mapped_value(16_535, daysafter_mapping)
    # Answer independently checked http://www.wolframalpha.com/input/?i=2012-05-16+%2B+9379+days
    assert_equal Date.new(2038, 1, 19), TestMapper.new.mapped_value(9379, daysafter_mapping)
    assert_equal Date.new(1946, 5, 11),
                 TestMapper.new.mapped_value(16_900, 'daysafter' => '1900-02-01')
    assert_equal Date.new(2014, 4, 8),
                 TestMapper.new.mapped_value(16_900, 'daysafter' => '1967-12-31')
    assert_equal Date.new(2046, 4, 9),
                 TestMapper.new.mapped_value(16_900, 'daysafter' => '2000-01-01')
  end

  test 'line mapping should create valid hash' do
    line_hash = TestMapper.new.mapped_line(['1 test road, testtown'], simple_mapping)
    assert_equal '1 test road, testtown', line_hash['address']
    assert_equal '1 test road, testtown', line_hash[:rawtext]['patient address']
  end

  test 'line mapping should create valid hash with blank cleaned value' do
    assert_equal '', TestMapper.new.mapped_value('98', clean_opcs_mapping)
    line_hash = TestMapper.new.mapped_line(['98'], simple_mapping_with_clean_opcs)
    assert_nil line_hash['primaryprocedures']
    assert_equal '98', line_hash[:rawtext]['primaryprocedures']
  end

  test 'line mapping should create valid hash with join' do
    line_hash = TestMapper.new.mapped_line(%w(Catherine Elizabeth), join_mapping)
    assert_equal 'Catherine Elizabeth', line_hash['forenames']
    assert_equal 'Catherine', line_hash[:rawtext]['forename1']
    assert_equal 'Elizabeth', line_hash[:rawtext]['forename2']
  end

  test 'line mapping should create valid hash with rawtext only' do
    line_hash = TestMapper.new.mapped_line(['otherinfo'], unused_mapping)
    assert_equal 1, line_hash.length
    assert_equal 'otherinfo', line_hash[:rawtext]['extra']
  end

  test 'should create valid hash with unused cross populate' do
    line_hash = TestMapper.new.mapped_line(['Bob Fossil', 'C1234'], cross_populate_mapping)
    assert_equal 'Bob Fossil', line_hash[:rawtext]['referringclinicianname']
    assert_equal 'C1234', line_hash[:rawtext]['referringcliniciancode']

    assert_equal 'Bob Fossil', line_hash['consultantname']
    assert_equal 'C1234', line_hash['consultantcode']
  end

  test 'should create valid hash with used cross populate' do
    line_hash = TestMapper.new.mapped_line(['Bob Fossil', ''], cross_populate_mapping)
    assert_equal 'Bob Fossil', line_hash[:rawtext]['referringclinicianname']
    assert_equal '', line_hash[:rawtext]['referringcliniciancode']

    assert_equal 'Bob Fossil', line_hash['consultantname']
    assert_equal 'Bob Fossil', line_hash['consultantcode']
  end

  test 'should create valid hash with unused cross populate replace' do
    line_hash = TestMapper.new.mapped_line(['Bob Fossil', 'C1234'], cross_populate_replace_mapping)
    assert_equal 'Bob Fossil', line_hash[:rawtext]['referringclinicianname']
    assert_equal 'C1234', line_hash[:rawtext]['referringcliniciancode']

    assert_equal 'Bob Fossil', line_hash['consultantname']
    assert_equal 'C1234', line_hash['consultantcode']
  end

  test 'should create valid hash with used cross populate with replace' do
    line_hash = TestMapper.new.mapped_line(['Bob Fossil', ''], cross_populate_replace_mapping)
    assert_equal 'Bob Fossil', line_hash[:rawtext]['referringclinicianname']
    assert_equal '', line_hash[:rawtext]['referringcliniciancode']

    assert_equal 'Bob Fossil', line_hash['consultantname']
    assert_equal 'ROBERT FOSSIL', line_hash['consultantcode']
  end

  test 'should create valid hash with used cross populate without replace' do
    line_hash = TestMapper.new.mapped_line(['Bob Smith', ''], cross_populate_replace_mapping)
    assert_equal 'Bob Smith', line_hash[:rawtext]['referringclinicianname']
    assert_equal '', line_hash[:rawtext]['referringcliniciancode']

    assert_equal 'Bob Smith', line_hash['consultantname']
    assert_equal 'Bob Smith', line_hash['consultantcode']
  end

  test 'should create valid hash with unused cross populate map' do
    line_hash = TestMapper.new.mapped_line(['Bob Fossil', 'C1234'], cross_populate_map_mapping)
    assert_equal 'Bob Fossil', line_hash[:rawtext]['referringclinicianname']
    assert_equal 'C1234', line_hash[:rawtext]['referringcliniciancode']

    assert_equal 'Bob Fossil', line_hash['consultantname']
    assert_equal 'C1234', line_hash['consultantcode']
  end

  test 'should create valid hash with used cross populate with map' do
    line_hash = TestMapper.new.mapped_line(['Bob Fossil', ''], cross_populate_map_mapping)
    assert_equal 'Bob Fossil', line_hash[:rawtext]['referringclinicianname']
    assert_equal '', line_hash[:rawtext]['referringcliniciancode']

    assert_equal 'Bob Fossil', line_hash['consultantname']
    assert_equal 'C5678', line_hash['consultantcode']
  end

  test 'should create valid hash with used cross populate with map with no p2 map' do
    line_hash = TestMapper.new.mapped_line(['something', ''], cross_populate_map_mapping)
    assert_equal 'something', line_hash[:rawtext]['referringclinicianname']
    assert_equal '', line_hash[:rawtext]['referringcliniciancode']

    assert_equal 'something', line_hash['consultantname']
    assert_equal 'something', line_hash['consultantcode']
  end

  test 'should create valid hash with used cross populate with map with p1 mapped' do
    line_hash = TestMapper.new.mapped_line(['Bob Fossil', 'P2'],
                                           cross_populate_map_reverse_priority_mapping)
    assert_equal 'Bob Fossil', line_hash[:rawtext]['referringclinicianname']
    assert_equal 'P2', line_hash[:rawtext]['referringcliniciancode']

    assert_equal 'Bob Fossil', line_hash['consultantname']
    assert_equal 'C5678', line_hash['consultantcode']
  end

  test 'should create valid hash with used cross populate with map with p1 mapped out' do
    line_hash = TestMapper.new.mapped_line(['Bolo', 'P2'],
                                           cross_populate_map_reverse_priority_mapping)
    assert_equal 'Bolo', line_hash[:rawtext]['referringclinicianname']
    assert_equal 'P2', line_hash[:rawtext]['referringcliniciancode']

    assert_equal 'Bolo', line_hash['consultantname']
    assert_equal 'P2', line_hash['consultantcode']
  end

  test 'should create valid hash with used cross populate with map with p1 no map' do
    line_hash = TestMapper.new.mapped_line(['something', 'P2'],
                                           cross_populate_map_reverse_priority_mapping)
    assert_equal 'something', line_hash[:rawtext]['referringclinicianname']
    assert_equal 'P2', line_hash[:rawtext]['referringcliniciancode']

    assert_equal 'something', line_hash['consultantname']
    assert_equal 'something', line_hash['consultantcode']
  end

  test 'should create valid hash with used cross populate without map' do
    line_hash = TestMapper.new.mapped_line(['Bob Smith', ''], cross_populate_map_mapping)
    assert_equal 'Bob Smith', line_hash[:rawtext]['referringclinicianname']
    assert_equal '', line_hash[:rawtext]['referringcliniciancode']

    assert_equal 'Bob Smith', line_hash['consultantname']
    assert_equal 'Bob Smith', line_hash['consultantcode']
  end

  test 'should create valid hash with used cross populate without map and priorities' do
    line_hash = TestMapper.new.mapped_line(['Pass', '', 'Fail', 'Large Fail'],
                                           cross_populate_order_mapping)
    assert_equal 'Pass', line_hash[:rawtext]['referringclinicianname']
    assert_equal '', line_hash[:rawtext]['referringcliniciancode']

    assert_equal 'Pass', line_hash['consultantname']
    assert_equal 'Pass', line_hash['consultantcode']
  end

  test 'should create valid hash with used cross populate without priority' do
    line_hash = TestMapper.new.mapped_line(%w(Exists Not), cross_populate_no_priority)
    assert_equal 'Exists', line_hash[:rawtext]['columnoneraw']
    assert_equal 'Not', line_hash[:rawtext]['columntworaw']

    assert_equal 'Exists', line_hash['columnone']
    assert_equal 'Exists', line_hash['columntwo']
  end

  test 'should create equal hashes with standard mapping' do
    line_hash_without = TestMapper.new.mapped_line(
      ['Smith', 'John F', 'male', '01234567'], standard_mapping_without
    )
    line_hash_with = TestMapper.new.mapped_line(
      ['Smith', 'John F', 'male', '01234567'], standard_mapping_with
    )
    assert_equal line_hash_without, line_hash_with
  end

  test 'should merge standard mapping and normal mapping' do
    line_hash = TestMapper.new.mapped_line(['Smith'], standard_mapping_merge)
    assert_equal 'SMITH', line_hash['surname']
    assert_equal 'Smith', line_hash['surname2']
  end

  test 'should merge standard mapping in correct order' do
    line_hash = TestMapper.new.mapped_line(['Smith'], standard_mapping_column)
    assert_equal 'Smith', line_hash[:rawtext]['overriding_column_name']
    refute line_hash[:rawtext].include?('standard_mapping_column_name')
  end

  test 'should raise duplicate priority exception' do
    assert_raise(RuntimeError) do
      TestMapper.new.mapped_line(%w(A B), invalid_priorities)
    end
  end

  test 'should raise nonexistent standard mapping exception' do
    assert_raise(RuntimeError) do
      TestMapper.new.mapped_line(['A'], invalid_standard_mapping)
    end
  end

  test 'should not modify the standard mapping when using it' do
    # Take a deep copy of the original, using YAML serialization:
    standard_mappings = YAML.load(NdrImport::StandardMappings.mappings.to_yaml)

    TestMapper.new.mapped_line(['Smith'], YAML.load(<<-YML.strip_heredoc))
      - column: surname
        standard_mapping: surname
        mappings:
        - field: overwrite_surname
    YML

    assert_equal standard_mappings, NdrImport::StandardMappings.mappings
  end

  test 'should join blank first field with compacting' do
    line_hash = TestMapper.new.mapped_line(['', 'CB3 0DS'], joined_mapping_blank_start)
    assert_equal 'CB3 0DS', line_hash['address']
  end

  test 'should join blank first field without compacting' do
    line_hash = TestMapper.new.mapped_line(['', 'CB3 0DS'], joined_mapping_blank_start_uncompacted)
    assert_equal ',CB3 0DS', line_hash['address']
  end

  test 'line mapping should map date formats correctly' do
    real_date = Date.new(1927, 7, 6)
    incomings = %w( 06/07/1927  19270706     07/06/1927   06/07/27  06/JUL/27 )
    columns   = %w( dateofbirth receiveddate americandate shortdate funkydate )
    line_hash = TestMapper.new.mapped_line(incomings, date_mapping)

    columns.each do |column_name|
      assert_equal real_date, line_hash[column_name].to_date
    end
  end

  test 'should ignore columns marked do not capture' do
    line_hash = TestMapper.new.mapped_line(['rubbish'], do_not_capture_column)
    refute line_hash[:rawtext].include?('ignore_me')
  end

  test 'should decode base64 encoded word document' do
    test_file = @permanent_test_files.join('hello_world.doc')
    encoded_content = Base64.encode64(File.binread(test_file))
    line_hash = TestMapper.new.mapped_line([encoded_content], base64_mapping)
    assert_equal 'Hello world, this is a word document', line_hash[:rawtext]['base64']
  end

  test 'should decode base64 encoded docx document' do
    test_file = @permanent_test_files.join('hello_world.docx')
    encoded_content = Base64.encode64(File.binread(test_file))
    line_hash = TestMapper.new.mapped_line([encoded_content], base64_mapping)
    expected_content = "Hello world, this is a modern word document\n" \
                       "With more than one line of text\nThree in fact"

    assert_equal expected_content, line_hash[:rawtext]['base64']
  end

  test 'should decode word.doc' do
    test_file = @permanent_test_files.join('hello_world.doc')
    file_content = File.binread(test_file)
    text_content = TestMapper.new.send(:decode_raw_value, file_content, :word_doc)
    assert_equal 'Hello world, this is a word document', text_content
  end

  test 'should read word.doc stream' do
    test_file = @permanent_test_files.join('hello_world.doc')
    file_content = TestMapper.new.send(:read_word_stream, File.open(test_file, 'r'))
    assert_equal 'Hello world, this is a word document', file_content
  end

  test 'should handle blank values when attempting to decode_raw_value' do
    text_content = TestMapper.new.send(:decode_raw_value, '', :word_doc)
    assert_equal '', text_content
  end

  test 'should raise unknown encoding exception' do
    assert_raise(RuntimeError) do
      TestMapper.new.mapped_line(['A'], invalid_decode_mapping)
    end
  end
end
