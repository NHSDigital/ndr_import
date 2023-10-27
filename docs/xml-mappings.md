---
layout: page
title: XML mappings
permalink: /xml-mappings/
---

### Introduction
Extensible Markup Language (XML) is a markup language that provides rules to define any data. `ndr_import` allows that data to be mapped in the same way as tabular data.

XML can contain repeating data items/sections, which the column mappings would need to verbosely define. XML allows for unlimited repetition, so it would be very hard to have all columns accounted for.

`NdrImport::XML::Table` only requires each column to appear in the mapping once. It will identify any repeating data item/section xpaths that haven't been accounted for and create appropriate column mappings in memory.

The logic covers all current use cases; additional features may be needed if more use cases are identified.


### `NdrImport::Xml::Table`
`NdrImport::XML::Table` requires some additional configuration so that the "records" are correctly identified.

* `format` - this should always be `xml_table` so that ndr_import knows which handler to use
* `xml_record_xpath` - this is the xpath - relative to the root - that indicates the start of a new record
* `pattern_match_record_xpath` - setting this `true` treats the `xml_record_xpath` as a regular expression; the default is to treat it as a string
* `slurp` - setting this to `true` will ensure the data is slurped; the default is to stream the XML
* `yield_xml_record` - setting this to true will yield all "klasses" created from a single XML record (identified by `xml_record_xpath`); the default is to yield per klass


### `NdrImport::Xml::Table` example:
Given the below example data:

```xml
<root>
  <records>
    <record_1>
      <data_item>value</data_item>
      <another_data_item>Another value</another_data_item>
    </record_1>
    <record_2>
      <data_item>value</data_item>
      <another_data_item>Another value</another_data_item>
    </record_2>
  </records>
</root>
```

The `NdrImport::Xml::Table` mapping might look like:

```yaml
- !ruby/object:NdrImport::Xml::Table
  filename_pattern: !ruby/regexp //
  format: xml_table
  xml_record_xpath: 'records\/record_\d+'
  pattern_match_record_xpath: true
  slurp: false
  yield_xml_record: false
  columns:
  ...
```


### Column mappings:

The `column` should be the data item node name.

Outside of the normal column mappings (rawtext_name etc), columns will also define `xml_cell`. This is a hash containing configuration that ndr_import uses to find the data, identify if the data item is repeating, and then act accordingly.


`xml_cell` contains:

* `relative_path` - this is the relative path from the `xml_record_xpath` to the data item
* `attribute` - this is the attribute (if present) e.g. extension, code
* `multiple` - does this data item appear more than once within a klass? If set to true, additional column mappings will be added with a `_1`, `_2` etc suffix on the rawtext_name
* `increment_field_name` - similar to `multiple` above, but adds a suffix to each mapped field when set to true. This should only be set to true if the column has mapped fields
* `build_new_record` - this is only needed where column level klasses are defined. This should be set to false if you do not want an additional klass added to the masked mappings. This might be where you have a repeating item within a klass, but you only expect one instance of that klass within a "record", as defined by `xml_record_xpath`
* `klass_section` - this is the relative path from `xml_record_xpath` to the section that would trigger a new klass. If there is a data item flagged as `multiple`, the number of times `klass_section` appears determines if the klass should have a `#1`, `#2` etc suffix.


### Column examples:
```xml
<root>
  <records>
    <record_1>
      <section_1>
        <part_1>
          <repeating_item code=value />
          <repeating_item code=value />
          <another_data_item>Another value</another_data_item>
        </part_1>
      </section_1>
    </record_1>
  </records>
</root>
```
The below examples assume we're using the above `NdrImport::XmlTable` mapping

Example mapping for `another_data_item` which is a single, non-repeating data item:

```yaml
- column: repeating_item
  klass: SomeTestKlass
  rawtext_name: blah
  xml_cell:
    id:
    relative_path: section_1/part_1
    attribute:
```


Example mapping for `repeating_item`:

```yaml
- column: repeating_item
  klass: SomeTestKlass
  rawtext_name: blah
  xml_cell:
    id:
    relative_path: section_1/part_1
    attribute: code
    multiple: true
    increment_field_name: true
    build_new_record: false
```

If the `repeating_item` was expected to be in many klasses - where the `section_1` section triggered a new klass - the mapping would look like:

```yaml
- column: repeating_item
  klass: SomeTestKlass
  rawtext_name: blah
  xml_cell:
    id:
    relative_path: section_1/part_1
    attribute: code
    multiple: true
    increment_field_name: true
    klass_section: section_1
```


### Cheat sheet

|Scenario|multiple|increment_field_name|build_new_record|klass_section|
|---|---|---|---|---|
|Single data item, non repeating|false or omit key|false or omit key|false or omit key|omit key|
|Repeating data item, single klass expected|true|true (if mapped fields present)|false|omit key|
|Repeating data item, one or more klasses expected|true|true (if mapped fields present)|omit key|relative path to section|
