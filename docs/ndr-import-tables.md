---
layout: page
title: NdrImport::Table
permalink: /ndr-import-table/
---

Here is an example of a single NdrImport::Table mapping:

```yaml
---
!ruby/object:NdrImport::Table
canonical_name: test_data
filename_pattern: !ruby/regexp /file_1.xlsx/i
tablename_pattern: !ruby/regexp /tab_1/i
header_lines: 1
footer_lines: 0
klass: AClass
columns:
- column: one
- column: two
```

**NdrImport::Table metadata**:

1. !ruby/object:NdrImport::Table - This is the class of the NdrImport::Table - other classes will be explained in further documentation
2. canonical_name - If you have many NdrImport::Table mappings within an mapping, the canonical_name can be used identify which table of data this mapping refers to.
3. filename_pattern - this is a regular expression that matches the file that this NdrImport::Table will map
4. tablename_pattern - If an xls[x] file contains many tabs, this regular expression can be used to match a tab name within the file matched by the filename_pattern
5. header_lines - The number of rows above the data
6. footer_lines - The number of rows below the data
7. klass - This class of record that will be created on import
8. columns - The column level mappings haven't changed, they are as per the [getting started](getting-started.md) documentation


**Delimited files:**

For tabular data that is not xls(x) or csv, often in a .txt file with several varieties of delimiter, we need to set the format as delimited and the delimiter as that files delimiter eg, a pipe |.

Example mapping:

```yaml
--- !ruby/object:NdrImport::Table
canonical_name: test_data
filename_pattern: !ruby/regexp /file_1.xlsx/i
tablename_pattern: !ruby/regexp /tab_1/i
header_lines: 1
footer_lines: 0
format: delimited
delimiter: '|'
klass: AClass
columns:
- column: one
- column: two
```

This will ensure that ndr_import recognises the data as a delimited file and uses the correct delimiter to parse it.

This type of tabular data can, on occasion, be malformed - usually an unexpectd " in a field, raising a CSV::MalformedCSVError: Illegal quoting in line 1. error. There is a liberal_parsing option that can be set to true in the meta data, meaning that every effort is made to parse the data eg:

```yaml
--- !ruby/object:NdrImport::Table
canonical_name: test_data
filename_pattern: !ruby/regexp /file_1.xlsx/i
tablename_pattern: !ruby/regexp /tab_1/i
header_lines: 1
footer_lines: 0
format: delimited
delimiter: '|'
liberal_parsing: true
klass: Aclass
columns:
- column: one
- column: two
```

Further reading around liberal parsing can be found [here](https://bigbinary.com/blog/ruby-2-4-introduces-liberal_parsing-option-for-parsing-bad-csv-data)


**Multiple NdrImport::Table mappings with a single mapping document:**

It is common to receive multiple tables of data in a single upload; this can be multiple csv, txt, pdf or word files within a .zip, multiple tabs in a single xls[x] file or multiple xsl[x] files with 1 or more tabs per file. NdrImport::Table mappings allow you map all of those tables within a single mapping, meaning that multiple files can be loaded at the same time.

Here is an example of a multi NdrImport::Table mapping:

```yaml
---
- !ruby/object:NdrImport::Table
  canonical_name: test_data
  filename_pattern: !ruby/regexp /file_1.xlsx/i
  tablename_pattern: !ruby/regexp /tab_1/i
  header_lines: 1
  footer_lines: 0
  klass: AClass
  columns:
  - column: one
  - column: two

- !ruby/object:NdrImport::Table
  canonical_name: real_data
  filename_pattern: !ruby/regexp /file_1.xlsx/i
  tablename_pattern: !ruby/regexp /tab_2/i
  header_lines: 1
  footer_lines: 0
  klass: Bclass
  columns:
  - column: three
  - column: four
```

In this example, there are two tables of data, both from file_1.xlsx, with a mapping each for tab_1 and tab_2.


**Unwanted data**

In tabular files, if there IS data that ndr_import should ignore at the end of a file, a *last_data_column* can be defined in the NdrImport::Table.
*last_data_column* can defined as either a number or as an excel column reference, eg 'EF'. The mapper will then stop extracting data from the file after that column.

Example mapping
```yaml
--- !ruby/object:NdrImport::Table
canonical_name: test_data
filename_pattern: !ruby/regexp /file_1.xlsx/i
tablename_pattern: !ruby/regexp /tab_1/i
header_lines: 1
footer_lines: 0
last_data_column: 'EF'
klass: AClass
columns:
- column: one
- column