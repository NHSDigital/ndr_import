---
layout: page
title: Date Formats
permalink: /date-formats/
---

When loading data, one of the most common errors is 'invalid date value "..."'. This is happens when the incoming date format does not match the format specified in the mapping.

For example, if the incoming data value is '2000-01-01' and the column mapping is:

```yaml
- column: dob
  rawtext_name: dateofbirth
  mappings:
  - field: dateofbirth
    format: %d/%m/%Y
```

The importer will raise an error saying invalid date value "2000-01-01" because it is trying to load a %Y-%m-%d date in the format of %d/%m/%Y.

It is therefore very important that the incoming date format and the format defined in the mapping match.

**Note**: only dates that are loaded as a string need to given a format in the mapping. Data that is loaded in excel spreadsheets, where the date columns are formatted as Date, will not need to be given a format.

When loading data in Excel, it's important to be mindful that Excel can display dates in format that doesn't match underlying data. For example, Excel can store dates as a number, which is the number of days since a given epoch date. If when loading data, you are presented with the error 'invalid date value "10145"', this is a good indication that the data loaded is in this format.

This date format can be dealt with in the mapping, using the below syntax:

```yaml
- column: dob
  rawtext_name: dateofbirth
  mappings:
  - field: dateofbirth
    daysafter: 1899-12-30
```

'1899-12-30' is the epoch date in this example, it is +vital+ that this epoch date is correct in your mapping. The importer adds the number (as a number of days) provided in the incoming data to the given epoch date to produce the date.

For example, given the value '10145', the above mapping would load a date of 10/10/1927.
