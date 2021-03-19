---
layout: page
title: Virtual Columns
permalink: /virtual-columns/
---

### Filename

Sometimes the filename contains information that isn't held anywhere else in the file.

By map the filename to a virtual column you can use and transform it in the usual way.

Example mapping of a file called `RGT_collection.xls`:

```yaml
---
  - column: :filename
    mappings:
    - field: providercode
      replace:
      - ? !ruby/regexp /_collection\.xls\z/i
        : ''
      - ? !ruby/regexp /\AAddenbrookes\z/i
        : 'RGT01'
...
```

produces the field `'providercode': 'RGT01'` and the rawtext will contain: `filename: RGT_collection.xls`.
