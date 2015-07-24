# NdrImport

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ndr_import'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ndr_import

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( https://github.com/[my-github-username]/ndr_import/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Please note that this project is released with a Contributor Code of Conduct. By participating in this project you agree to abide by its terms.

## Updating gem version and repackaging
### In the gem
1. fix gem (and test) - commit
2. bump version and package (bundle exec rake build) - commit
3. test
4. dcommit gem
5. gem install pkg/ndr_import-0.5.6.gem

### In era (or wherever you're using the gem)
1. bump version in gemfile
2. bundle install --local
3. add all unstaged files - commit
4. test
5. dcommit
