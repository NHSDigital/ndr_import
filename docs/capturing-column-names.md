---
layout: page
title: Capturing Column Names in Mapped Data
permalink: /capturing-column-names/
---

Column names themselves may contain data that should be included in each record. For example VCF files have a column name that is a Lab Number and it should be included on all records.

In order to store the column name in each record, include the `map_columname_to` key at the column level, with the value being the desired field and rawtext name.


Example mapping

---
    - column: column_one
      mappings:
      - field: field_one
    - column: abc123
      map_columname_to: 'columnname_field'
      mappings:
      - field: field_two

Example data:

```
"column_one","abc123"
"one","two"
```

This would result in:

```
{ 'field_one' => 'one',
  'columnname_field' => 'abc123',
  'field_two' => 'two',
  rawtext: { 'column_one' => 'one', 'abc123' => 'two', 'columnname_field' => 'abc123' } }
```
