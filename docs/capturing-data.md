---
layout: page
title: Capturing Data
permalink: /capturing-data/
---

Once every record has been [identified](identifying-and-splitting-records.md) using the non_tabular_row section of the mapping, data items can then be captured from each record.

Each record is an array of lines, the simplest way to is capturing data is from a single line, using the line number of the record.

### Capturing data from one line using line numbers:

If you wanted to capture the entire first row of the data in every record, the syntax would be:

```yaml
---
non_tabular_row:
  start_line_pattern: !ruby/regexp /\A-{6}\z/
  end_line_pattern: !ruby/regexp /\A\+{6}\z/
columns:
- column: example_capture
  non_tabular_cell:
    lines: 0
    capture: !ruby/regexp /\A(.*)\z/
  mappings:
  - field: example_field
```

The key columns: is defined, which contains an array of column: mappings. In this instance, only one column is defined, so columns: contains an array of 1.

The column name is defined (example_capture in this example), as with tabular mappings, the rawtext_name defaults to the column name unless overwritten by the presence of rawtext_name in the column mapping. As the column names are defined by the user writing the YAML mapping, rather than the incoming data, the column names should be the relevant canonical names.

The column mapping must then define non_tabular_cell: which in turn must define lines: and capture:


**lines:** is an integer index between 0 (first line of the record which can be captured) and -1 (last line of record that can be captured), where only one line number can be defined.

**capture:** is a regular expression that defines which part of the line defined by lines: will be captured.  The first captured group is always returned. 

In this example, the first line of each record is captured (line 0) and then the whole line is captured using the regexp /\A(.*)\z/. That data is then mapped to a field using the same syntax as tabular YAML mappings. 

**Note:** [Standard mappings](standard-yaml-mappings.md) are available on those fields with the functionality, eg:

```yaml
---
non_tabular_row:
  start_line_pattern: !ruby/regexp /_regexp_/
  end_line_pattern: !ruby/regexp /_regexp_/
columns:
- standard_mappings: nhsnumber
  non_tabular_cell:
    lines: 0
    capture: !ruby/regexp /_regexp_/
```

### Capturing data from a range of lines using line numbers:

If the data that requires capturing covers more than one line, a range of lines can be captured using line numbers.

**Note:** Lines are right stripped and only non-blank lines will be captured.

The syntax for capturing a range of lines is:

```yaml
---
non_tabular_row:
  start_line_pattern: !ruby/regexp /\A-{6}\z/
  end_line_pattern: !ruby/regexp /\A\+{6}\z/
columns:
- column: example_capture
  non_tabular_cell:
    lines: 0
    capture: !ruby/regexp /\A(.*)\z/
  mappings:
  - field: example_field
- column: example_capture2
  non_tabular_cell:
    lines: !ruby/range
      begin: 1
      end: -1
      excl: false
    capture: !ruby/regexp /\A(\w+)\b/
    join: "\n"
  mappings:
  - field: example_field2
```


This is a continuation of the previous example. A second column mapping has been defined in columns; example_capture2. non_tabular_cell is defined as before however lines is now defined as a !ruby/range, which in turn defines begin: end: and excl:.


**begin:** identifies which line the captured range will start on
**end:** identifies which line the range ends on
**excl:** true or false - defines whether or not the last line in the range is excluded from the capture.

capture: is as before, this identifies which part of each line in the range is captured using a regexp.

**join:** defines how the captured data from the range of lines should be joined. In this example the lines are joined with a new line character "\n"

mappings: is defined in the same way as tabular data.

### Capturing data from a range of lines using Regular Expressions:

If the data that requires capturing is on more than one line and the position (line number(s)) is not consistent between records, regular expressions can be used to identify the begin: and end: lines in each record.

Where lines: had previously been defined as !ruby/range, when using regular expressions lines: will be defined as !ruby/object:RegexpRange.

For example:

```yaml
---
non_tabular_row:
  start_line_pattern: !ruby/regexp /\A-{6}\z/
  end_line_pattern: !ruby/regexp /\A\+{6}\z/
columns:
- column: example_capture
  non_tabular_cell:
    lines: 0
    capture: !ruby/regexp /\A(.*)\z/
  mappings:
  - field: example_field
- column: example_capture2
  non_tabular_cell:
    lines: !ruby/object:RegexpRange
      begin: !ruby/regexp /_regexp_/
      end: !ruby/regexp /_regexp_/
      excl: false
    capture: !ruby/regexp /\A(.*)\z/
    join: "\n"
  mappings:
  - field: example_field2
```

Line numbers can still be used in combination with a regexp if the begin: or end: line number is consistent between records, eg:

```yaml
- column: example_capture2
  non_tabular_cell:
    lines: !ruby/object:RegexpRange
      begin: 1
      end: !ruby/regexp /_regexp_/
      excl: false
    capture: !ruby/regexp /\A(.*)\z/
    join: "\n"
  mappings:
  - field: example_field2
```

or

```yaml
- column: example_capture2
  non_tabular_cell:
    lines: !ruby/object:RegexpRange
      begin: !ruby/regexp /_regexp_/
      end: -1
      excl: false
    capture: !ruby/regexp /\A(.*)\z/
    join: "\n"
  mappings:
  - field: example_field2
```


In the below example mapping, a RegexpRange is being used to capture a range starting with a line matching this regexp /\AReport:\s\d\d-\d\d-\d{4}/, finishing on the last line of each record, line -1. The last line in the range is wanted, so exlc: is false. 

Once that range of lines has been identified, the mapping then captures everything from each line in the range, remembering that each line is right stripped.

```yaml
---
non_tabular_row:
  start_line_pattern: !ruby/regexp /\A-{6}\z/
  end_line_pattern: !ruby/regexp /\A\+{6}\z/
columns:
- column: example_capture
  non_tabular_cell:
    lines: 0
    capture: !ruby/regexp /\A(.*)\z/
  mappings:
  - field: example_field
- column: example_capture2
  non_tabular_cell:
    lines: !ruby/object:RegexpRange
      begin: !ruby/regexp /\AReport:\s\d\d-\d\d-\d{4}/
      end: -1
      excl: false
    capture: !ruby/regexp /\A(.*)\z/
    join: "\n"
  mappings:
  - field: example_field2
```