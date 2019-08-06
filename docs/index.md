---
# Feel free to add content and custom Front Matter to this file.
# To modify the layout, see https://jekyllrb.com/docs/themes/#overriding-theme-defaults

layout: home
---

Welcome to the ndr_import wiki.

## Data Transformation

The NdrImport transformation engine (or "mapper"), is driven by configuration mappings that we usually store in YAML. They turn tabulated data into a hash of key/value pairs of field names and transformed values, plus an additional :rawtext key that contains a hash of canonical field names and raw values.

For example, given the data:
```ruby
['One','Two']
```
and the YAML mapping:
```yaml
---
- column: raw_foo
  mappings:
  - field: foo
    clean: :name
- column: raw_bar
  mappings:
  - field: bar
```
the mapper would produce:
```ruby
{ 'foo' => 'ONE', 'bar' => 'Two', :rawtext => { 'raw_foo' => 'One', 'raw_bar' => 'Two' } }
```

Typically we store the transformed hash using ActiveRecord within a Rails application:

```ruby
OurModel.create(mapped_hash)
```

but there is nothing preventing its use with MongoDB or any other datastore.

For more information on writing these YAML mappings, please read the [YAML Mapping User Guide](yaml-mapping-user-guide.md).
