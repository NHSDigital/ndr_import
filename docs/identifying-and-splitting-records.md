---
layout: page
title: Identifying and Splitting Records
permalink: /identifying-and-splitting-records/
---

In order to accurately identify and separate all records in nontabular data, the following needs to be established:

* What is the start_line_pattern (regular expression) that signifies the start of a record?
* Is there is a end_line_pattern (regular expression) that signifies the end of a record?
* Does the file start_in_a_record? true or false. 
  > Is there is a start_line_pattern present for the first record?
* Does the file end_in_a_record? true or false. 
  > Is there is an end_line_pattern present for the last record?
* Do you need to capture_start_line? true or false
  > Does the start_line_pattern contain data that you would like the capture?


Below is the starting point for any nontabular YAML mapping, where the above can be defined:

```yaml
---
non_tabular_row:
  start_line_pattern: !ruby/regexp //
  end_line_pattern: !ruby/regexp //
  start_in_a_record:
  end_in_a_record:
  capture_start_line:
```


### Common non_tabular_row mapping examples:

**Example 1**:

For data that contains both a start_line_pattern and end_line_pattern for every record, and where the line being used to signify
the start_line_pattern doesn't contain any data that requires capturing, the non_tabular_row mapping would be the following:

```yaml
---
non_tabular_row:
  start_line_pattern: !ruby/regexp /\A-{6}\z/
  end_line_pattern: !ruby/regexp /\A\+{6}\z/
  capture_start_line: false
  start_in_a_record: false
  end_in_a_record: false
```

Here example regular expression (regexp) patterns for start_line_pattern and end_line_pattern have been defined. The start_line_pattern of each record does not need to be
 captured, so capture_start_line is set to false. The data does not start_in_a_record or end_in_a_record, so both are also set to false.

Given that capture_start_line, start_in_a_record and end_in_record are all set the false, they can be removed from the mapping as this is their 
default behavior, therefore the non_tabular_row mapping could look like the following:

```yaml
---
non_tabular_row:
  start_line_pattern: !ruby/regexp /\A-{6}\z/
  end_line_pattern: !ruby/regexp /\A\+{6}\z/
```

**Example 2**:

For data that contains a start_line_pattern for every record but no end_line_pattern, and where the 
start_line_pattern does not need capturing, the non_tabular_row mapping would be the following:

```yaml
---
non_tabular_row:
  start_line_pattern: !ruby/regexp /\A-{6}\z/
  end_in_a_record: true
```

The start_line_pattern has been defined, there is no end_line_pattern to be defined so that part of the mapping can be removed. The data does not 
start_in_a_record as there is a start_line_pattern before the first record, as a result capture_start_line is false. Finally, end_in_a_record is 
true as there is no end_line_pattern to signify the end of the last record.

**GOTCHA**: If end_in_a_record is left undefined, the last record will not be identified as end_in_a_record defaults to false

**Example 3**:

For data that contains a line which separates records, but does not appear before the first record or after the 
last record and where the separating line does not need to be captured, the non_tabular_row mapping 
would look like the following:

```yaml
---
non_tabular_row:
  start_line_pattern: !ruby/regexp /\A={8}\z/
  start_in_a_record: true
  end_in_a_record: true
```

Here we treat the separating line as the start_line_pattern, and set start_in_a_record to true as there is no start_line_pattern before the first 
record. Similarly, we set end_in_a_record to true as there is no end_line_pattern after the last record.  There is no end_line_pattern to be 
defined so that part of the mapping can be removed, along with capture_start_line as it is set to false.

**GOTCHA**: If only a start_line_pattern is defined, with start_in_a_record and end_in_a_record left undefined, neither the first and last record would be captured. 

**Example 4**:

For data that contains a start_line_pattern for every record but no end_line_pattern and where the start line does require capturing because it 
contains data, the non_tabular_row mapping would be the following:

```yaml
---
non_tabular_row:
  start_line_pattern: !ruby/regexp /\AH,\d{8}-/
  capture_start_line: true
  start_in_a_record: false
  end_in_a_record: true
```

Here the start_line_pattern has been defined, capture_start_line has been set to true, as a result start_in_a_record needs to be set to false. 
Finally, end_in_a_record is set to true as there is no end_line_pattern after the last record.


**GOTCHA**: _part 1_
If capture_start_line is left undefined, data from the start line of each record cannot be captured as capture_start_line is false by default.

**GOTCHA**: _part 2_
If end_in_a_record is left undefined, the last record will not be identified as end_in_a_record is false by default.


### Notes: 

The non_tabular_row mapping can be written verbosely if you find this improves the readability. For instance, example 3 could be written as follows:

```yaml
---
non_tabular_row:
  start_line_pattern: !ruby/regexp /\A={8}\z/
 # no end_line_pattern present
 # end_line_pattern: !ruby/regexp //
  capture_start_line: false
  start_in_a_record: true
  end_in_a_record: true
```

### Removing Lines:

Lines of data can be removed/ignored if there is data that you would not like to be captured. For example, a header and/or footer on each page that doesn't align with the start and end of each record.

Lines to be removed can be matched either as a string comparison or by using a regexp. This also makes up part of the non_tabular_row mapping. 

Example:

```yaml
---
non_tabular_row:
#  start_in_a_record: false
#  end_in_record: false
  capture_start_line: false
  start_line_pattern: !ruby/regexp /\A-{6}\z/
  end_line_pattern: !ruby/regexp /\A\+{6}\z/
  remove_lines:
    header:
    - NYCRIS
    - !ruby/regexp /Page \d+/
    footer:
    - PDF by PDFmaker
```

The keys (header: and footer: in the above example) can be labelled as anything, but labeling them as something descriptive is advised.
Each of them containing an array of lines to be removed.

**GOTCHA**: Lines will only be removed if every line in a given array is matched in the order they are defined in the mapping.
