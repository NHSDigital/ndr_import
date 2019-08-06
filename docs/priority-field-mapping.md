---
layout: page
title: Priority Field Mapping
permalink: /priority-field-mapping/
---

Multiple incoming columns can be mapped to a single field on a priority basis.

The mapper will firstly map the priority 1 column to the given field, if this is column empty, it will then look in priority 2 column and so on.

For example, if a data provider sends the treatment_organisation_code and the organisation_code, we would firstly map the treatment_organisation_code to the providercode field, as this provides greater granularity. However, if that column is empty, we would then look in organisation_code column and map that to providercode.

Example mapping:

```yaml
---
- column: organisation_code
  rawtext_name: submitting_providercode
  mappings:
  - field: providercode
    priority: 2
- column: treating_organisation_code
  rawtext_name: providercode
  mappings:
  - field: providercode
    priority: 1
```
