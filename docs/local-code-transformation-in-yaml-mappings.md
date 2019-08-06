---
layout: page
title: Local Code Transformation in YAML Mappings
permalink: /local-code-transformation-in-yaml-mappings/
---

When receiving various local codes/initials/names that relate to national codes (GMC, NACS, etc) we deal with these by having a replacement transformation (lookup) in the mapping for that provider. 

For example:

```yaml
  mappings:
  - field: consultantcode
    replace:
    - ? !ruby/regexp /\ADR A Smith\z/i
      : 'C1234567'
    - ? !ruby/regexp /\AMr A Jones\z/i
      : 'C2345678'
    - ? !ruby/regexp /\AProf J Bloggs\z/i
      : 'C9999998'
```

or

```yaml
  mappings:
  - field: orgcodepathreport
    replace:
    - ? !ruby/regexp /\AADD\z/
      : 'RGT01'
    - ? !ruby/regexp /\ANAN\z/
      : 'RGM01'
```

If we receive a local code from the data provider, we would ask them for a lookup table, which can then be inserted into the mapping. If such a lookup table isn't forthcoming, we would take the time to put one together and return it to the data provider, asking them to check it and sign it off. In the meantime, all local codes can be mapped to the relevant unknown national code (e.g. C9999998 for Unknown Consultant) so that the data can be loaded. The YAML mapping can then be changed once the lookup is available.

If a new local code comes in that isn't in the mapping lookup, it will inevitably raise an error further downstream, if you validate the field as a national code. We would then contact the data provider asking for the relevant national code and add it to the mapping. If a national code can't be found, we would then map that local code to the relevant unknown national code, it will therefore not raise an error again in the future. These mappings can take quite a bit of work to set up initially, but are then very easily maintained and save a lot of time with not having to correct invalid codes further downstream.
