# NdrImport

This is the Public Health England (PHE) National Disease Registers (NDR) Import ETL ruby gem, providing:

1. file import helper modules for *extracting* data from delimited files (csv, pipe, tab, thorn), .xls(x) spreadsheets, .doc word documents, PDF, XML and Zip files.
2. mapper modules for *transforming* tabular and non-tabular data.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ndr_import', :git => 'https://github.com/PublicHealthEngland/ndr_import.git'
```

And then execute:

    $ bundle

Or install it yourself by cloning the project, then executing:

    $ gem install ndr_import.gem

## Usage

To add the ability to extract data from PDFs and transform the data they contain to a hash of key value pairs, for example, add the following lines to your code to your importer class:

```ruby
require 'ndr_import/helpers/file/pdf'
require 'ndr_import/mapper'
require 'ndr_import/non_tabular_file_helper'

class MyImporter
  include NdrImport::Helpers::File::Pdf
  include UnifiedSources::Import::Mapper
  include UnifiedSources::Import::NonTabularFileHelper

	# Your code goes here
end
```

NOTE: The UnifiedSources::Import namespace is carried over from the code as it existed prior to being a converted into this gem.
It will be corrected in a later major revision.

More information on the workings of the mapper will be available in the wiki once we have transferred it from our private task management system.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/ndr_import/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Please note that this project is released with a Contributor Code of Conduct. By participating in this project you agree to abide by its terms.

## Test Data

All test data in this repository is fictitious. Any resemblance to real persons, living or dead, is purely coincidental although Mighty Boosh references have been used in some tests.

Note: Real codes exist in the tests, postcodes for example, but bear no relation to real patient data. Please ensure that you *always* only ever commit dummy data when contributing to this project.
