## [Unreleased]
### Fixed
* Bump `seven_zip_ruby` requirement for Ruby 2.7 support

### Added
* Added the ability to define a virtual :filename column

## 10.1.1 / 2021-03-15
### Fixed
* XML: ensure invalid control character *references* are also escaped (#64)

## 10.1.0 / 2021-03-08
### Added
* Allow optional `last_data_column` in NdrImport::Table mappings (#61)

## 10.0.0 / 2021-02-22
### Changed
* By default, escape any control characters found in XML (#60)

## 9.1.0 / 2021-02-01
### Added
* `CSVLibrary` is now deprecated.
* Handle xlsm files

### Fixed
* Fix `CSVLibrary.foreach` on Ruby 3.0
* Updated jekyll bundle

## 9.0.3 / 2021-01-04
### Fixed
* Address issue importing multiple files against the same table (#54)

### Changed
* ensure keyword args are properly splatted for ruby 2.7

### Added
* Ruby 2.7 to travis matrix

## 9.0.2 / 2020-08-14
### Changed
* Configure Nokogiri with HUGE for large xml files

## 9.0.1 / 2020-03-26
### Fixed
* bumps to `nokogiri` / `spreadsheet` / `rubyzip` dependencies

## 9.0.0 / 2019-07-31
### Changed
* `File::Xml` will now stream XML files by default. Use `slurp: true` for the old behaviour. (#43)

### Added
* Add `XmlStreaming` helper, for more performant handling of large XML documents with Nokogiri. (#43)

## 8.6.0 / 2019-06-07
### Added
* Allow conditional preservation of blank lines when joining lines in non-tabular data (#41)

## 8.5.2 / 2019-05-17
### Fixed
* Fixed issue with `file_password` option key as a String or Symbol
* Tempfiles now take their encoding from the incoming string/stream

## 8.5.1 / 2019-05-15
### Added
* Add data loader tools (#39)

### Fixed
* Update Ruby/Rails supported versions. 2.5/5.2 is now minimum

## 8.5.0 / 2019-05-01
### Added
* Allow encypted docx/xlsx files to be read using `:file_password` option (#37)

## 8.4.0 / 2019-03-15
### Added
* Added ability to extract and transform PDF form data (#24)

## 8.3.0 / 2019-03-04
### Added
* Allow `klass` in the column level mapping to be embedded array.

## 8.2.0 / 2019-02-25
### Added
* Support automatically generating a per row identifier with `row_identifier` (#34)

## 8.1.0 / 2019-01-08
### Added
* Support `liberal_parsing` when using the delimited helper
* Support for Ruby 2.6. Rails 5.0 / Ruby 2.4 is now the minimum.

## 8.0.0 / 2018-11-26
### Changed
* Strip non tabular captured values by default (#28)

### Added
* Add validations to field mappings (#27)
* control `ndr_table` serialise order with `encode_with` method (#30)
* Added a 7-Zip file handler

## 7.0.0 / 2018-11-09
### Changed
* Breaking refactor of universal importer mixin (#25)
* Update `pdf-reader` version to support recent Rubies (#16)

## 6.4.1 / 2018-10-18
### Fixed
* bump nokogiri re: CVE-2018-14404

## 6.4.0 / 2018-10-17
### Added
* Allow `decode: :word_doc` to read a .DOCX file (#26)

## 6.3.0 / 2018-10-12
### Added
* Add XML file support (#22)
* Add liberal CSV parsing option (#24)
