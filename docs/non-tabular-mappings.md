---
layout: page
title: Non Tabular Mappings
permalink: /non-tabular-mappings/
---

### Please Note

If you have not done so, please read the [Getting Started](getting-started.md) wiki page, this covers the fundamentals of YAML mappings.

When creating a non-tabular YAML mapping, the format override needs to set as 'nontabular' (not including the quotes)


### Background

The non-tabular importer is simply a bolt-on to the standard mapper and works by turning incoming lines of text into a (temporary, in-memory) tabular structure, so that it can be processed by the standard mapper in the usual way. To that end, a standard tabular YAML mapping is augmented with the information needed to tabulate the data at both row and cell level.

The YAML mapping is parsed twice, firstly to extract the information needed to tabulate the data (lines highlighted with a + in green):

```diff
 ---
+non_tabular_row:
+  ...
+  ...
+columns:
+- column: example_capture1
+  non_tabular_cell:
+    ...
+    ...
   mappings:
   - field: example_field1
+- column: example_capture2
+  non_tabular_cell:
+    ...
+    ...
   mappings:
   - field: example_field2
```

and then by the standard mapper to process the tabulated data (again, lines highlighted with a + in green):

```diff
 ---
 non_tabular_row:
   ...
   ...
 columns:
+- column: example_capture1
   non_tabular_cell:
     ...
     ...
+  mappings:
+  - field: example_field1
+    clean: ...
+- column: example_capture2
   non_tabular_cell:
     ...
     ...
+  mappings:
+  - field: example_field2
+    clean: ...
```

### Contents

1. [Identifying and splitting records](identifying-and-splitting-records.md)
2. [Capturing Data](capturing-data.md)
3. [Examples]()
