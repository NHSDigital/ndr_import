---
layout: page
title: Standard YAML Mappings
permalink: /standard-yaml-mappings/
---

The YAML mapper can define a set of predefined standard mappings.

The following example is the list of standard mappings used within NHS Digital NDR:

```yaml
surname:
  column: surname
  rawtext_name: surname
  mappings:
  - field: surname
    clean: :name
previoussurname:
  column: previoussurname
  rawtext_name: previoussurname
  mappings:
  - field: previoussurname
    clean: :name
forenames:
  column: forenames
  rawtext_name: forenames
  mappings:
  - field: forenames
    clean: :name
sex:
  column: sex
  rawtext_name: sex
  mappings:
  - field: sex
    clean: :sex
nhsnumber:
  column: nhsnumber
  rawtext_name: nhsnumber
  mappings:
  - field: nhsnumber
    clean: :nhsnumber
postcode:
  column: postcode
  rawtext_name: postcode
  mappings: 
  - field: postcode
    clean: :postcode
```

They define a set of default mapping attributes for an incoming dataitem/column that DRY up the most common mappings.

For example, if you receive a column containing the NHS Number, labelled as "NHSNUMBER", then instead of defining the mapping as:

```yaml
- column: nhsnumber
  mappings:
  - field: nhsnumber
    clean: :nhsnumber
```

You could use:

```yaml
- standard_mapping: nhsnumber
```

**NOTE**: The standard mappings are defaults that can be overridden. If you receive a column containing the NHS Number, labelled as "NHS NUMBER", then instead of defining the mapping as:

```yaml
- column: nhs number
  rawtext_name: nhsnumber
  mappings:
  - field: nhsnumber
    clean: :nhsnumber
```

You could use:

```yaml
- standard_mapping: nhsnumber
  column: nhs number
```

or (because Ruby hashes are indifferent to the key order)

```yaml
- column: nhs number
  standard_mapping: nhsnumber
```

Although for readability, the former probably looks better.

**GOTCHA**: Because of the way hashes are merged, if you want to change the way a mapping maps to a field please be aware that your declaration overrides all the mappings for that column. I.e. 

```yaml
- standard_mapping: nhsnumber
  mappings:
  - field: someothernhsnumberfield
    clean: :nhsnumber
```

only maps to someothernhsnumberfield, not to nhsnumber and someothernhsnumberfield.
