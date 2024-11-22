---
layout: page
title: Zipped Field Mapping
permalink: /zipped-field-mapping/
---

Multiple incoming columns can be mapped to a single field, zipping array values (split from strings) together.

The mapper will identify  all the columns that have been mapped to a given `field`, with their `zip_order` and `split_char`. It will then take the string value for each of these and split them using the given `split_char`, resulting in an array of arrays.

Then using the `zip_order`, it'll take the first array and zip in the remaining arrays in their `zip_order`

Example mapping:

---
    - column: title
      mappings:
      - field: zipped_field
        zip_order: 1
        split_char: ","
    - column: value
      mappings:
      - field: zipped_field
        zip_order: 2

Example data:

```
"title","value"
"species,colour,legs","dog,brown,4"
```

This would result in:

```
{ "zipped_field"=>[["species", "dog"], ["colour", "brown"], ["legs", "4"]],
   :rawtext=>{"title"=>"species,colour,legs", "value"=>"dog,brown,4"}}
```

Reversing the `zip_order` in the mapping would result in:
```
{ "zipped_field"=>[["dog", "species"], ["brown", "colour"], ["4", "legs"]],
   :rawtext=>{"title"=>"species,colour,legs", "value"=>"dog,brown,4"}}
```

