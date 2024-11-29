---
layout: page
title: Regular Expression Column Names
permalink: /regexp-column-names/
---

Column names may differ between files, for example a lab number might be used a column name. In order to map the column, the column name can be a regular expression.

If the regular expression matches the column name in the raw file, the data will be mapped and loaded as expected.

If the regular expected does not match the column name, a column header error will be raised.

Example mapping

---
    - column: /\A[A-Z]+\d{3}\z/i
      mappings:
      - field: regex_field
    - column: two
      mappings:
      - field: two

Example data:

```
"abc123","two"
"regex_value","string_value"
```

This would result in:

```
{ 'regex_field' => 'regex_value', 'two' => 'string_value' },
   rawtext: { 'regex_field' => 'regex_value', 'two' => 'string_value' } }
```

However, the below data:

```
"1234abc","two"
"regex_value,string_value"
```

would result in a RuntimeError: 'Header is not valid! unexpected: ["1234abc"]'
