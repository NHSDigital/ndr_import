---
layout: page
title: Getting Started
permalink: /getting-started/
---

These notes are designed for users new to YAML mappings. Where appropriate, links will be added to more specific YAML documentation.

These mappings configure the [Extract, Transform, Load (ETL)](http://en.wikipedia.org/wiki/Extract,_transform,_load) mapper within NdrImport. In its simplest form, the purpose of a mapping is to take the raw incoming data and identify it with the correct canonical name in the rawtext and where applicable map the value to a field, whilst also performing any cleaning/transformation of the data on import.

It's important to note here that the data that goes into the rawtext remains untouched and is exactly as the data was loaded, any transformation/cleaning of data only takes place when it is mapped into a field. The raw source data remains unchanged in the rawtext so that it can be referenced when going back to data provider with any queries/QA issues. Furthermore, the rawtext maintains the transparency of any incoming data. This allows for internal audits to assess if any errors are the artifact of internal system processing or if the data was submitted containing these errors.

**Example Data**:
**Note**: Real data typically contains many more fields than shown in these examples, however the rules described here are transferable where applicable.

|Prov_code|Surname|Forename|dob|addr1|addr2|addr3|postcode|adm_method|
|---|---|---|---|---|---|---|---|---|
|RGT01|Mouse|Mickey|31/12/1950|20 London Road|Disney World|London|AB12 3CD|01|
|RGT01|Simpson|Homer|01/01/1970|742 Evergreen Terrace|Springfield|London||01|

The first step is to create a list of lower case column headings:
**Note**: It is advised to seed this from the header row of the data to avoid any typing errors.

```yaml
- column: prov_code
- column: surname
- column: forename
- column: dob
- column: addr1
- column: addr2
- column: addr3
- column: postcode
- column: adm_method
```

We will now take each of these columns in turn and label them with the appropriate canonical name for the rawtext and where applicable map the value to a field, whilst doing any cleaning or joining of fields. It is advised that you maintain a list of approved canonical names for each source type. NDR canonical names are maintained within their private ticketing system wiki.

Where the incoming column name differs from the of canonical rawtext_name, the rawtext_name needs to be defined in the mapping so that the data is labelled correctly in the rawtext.
Looking at the first column **prov_code**, let's assume that this differs from the canonical name **providercode**. Therefore we'll define the rawtext_name:

```yaml
- column: prov_code
  rawtext_name: providercode
```

In this example, let's assume that **prov_code** needs to be mapped to the field **providercode**:

```yaml
- column: prov_code
  rawtext_name: providercode
  mappings:
  - field: providercode
```

Moving onto the second column, **surname**, let's assume that the incoming column name is the same as the canonical name therefore we do not need to define the rawtext_name. However we do need to map the column to the field **surname**:

```yaml
- column: surname
  mappings:
  - field: surname
    clean: :name
```

You'll notice I have also added 'clean: :name' to the **surname** mapping. There is a list of [Inbuilt Cleaning Methods](inbuilt-cleaning-methods.md) which are used to clean data when it is mapped to a field.

For a selection of data items, this is very common behavior and so the [Standard YAML mappings](standard-yaml-mappings.md) syntax was created. In this particular instance, the **surname** mapping can be simply defined as:

```yaml
- standard_mapping: surname
```

Let's assume that the **forename** column differs from the canonical name **forenames**, so we need to define the rawtext_name in the mapping. However, the forenames field benefits from the functionality of the [Standard YAML mappings](standard-yaml-mappings.md). So instead of having to use the below mapping for the column **forename**:

```yaml
- column: forename
  rawtext_name: forenames
  mappings:
  - field: forenames
    clean: :name
```

We can overide the standard mapping's column definition, using:

```yaml
- standard_mapping: forenames
  column: forename
```

Again, let's assume that the **dob** column also differs from the canonical name **dateofbirth**. So the rawtext_name will be defined in the mapping, as well as the field name. If date is loaded as a string (ie not a Date formatted Excel cell), the format of the incoming date also needs to be defined:

```yaml
- column: dob
  rawtext_name: dateofbirth
  mappings:
  - field: dateofbirth
    format: %d/%m/%Y
```

For further information regarding date formats, please visit [Date Formats](date-formats.md).

Here is a list of the most common formats and how to represent them in a mapping:

|Syntax|Description|Sample Rendering|
|---|---|---|
||**Day**||
|%d |day of the month, 2 digits with leading zeros |“01” to “31”|
|%D |day of the week, textual, 3 letters |“Fri”|
||**Month**||
|%m |month |“01” to “12”|
|%b |month, textual, 3 letters |“Jan”|
|%B |month, textual, long |“January”|
||**Year**||
|%y |year, 2 digits |“99”|
|%Y |year, 4 digits |“1999”|
|%j |day of the year |“0” to “366”|
||**Hours**||
|%h |hour, 12-hour format |“01” to “12”|
|%H |hour, 24-hour format |“00” to “23”|
||**Minutes**||
|%M |minutes |“00” to “59”|
||**Seconds**||
|%S |seconds |“00” to “59”|

For further information please read the [Format Directives](http://apidock.com/ruby/DateTime/strftime)

In the example data, the **address** information is sent in a structured format over 3 separate columns, **addr1**, **addr2** and **addr3**. In order to map this data to the **address** field, we will need to join the 3 columns.

Firstly, let's assume that the incoming column names do not match the canonical name. We use the multiples convention shown below. We then need to define the field the data is being mapped to, the order in which each column appears in that field and then how we would like to join the data.

For example:
```yaml
- column: addr1
  rawtext_name: address1
  mappings:
  - field: address
    order: 1
    join: ', '
- column: addr2
  rawtext_name: address2
  mappings:
  - field: address
    order: 2
- column: addr3
  rawtext_name: address3
  mappings:
  - field: address
    order: 3
```

Here the we have used the rawtext_name multiples convention for rawtext_name: address (address1..N), specified the order in which we would like each of the columns to appear in the field and then joined the data using ', '.
*Note:* join: only needs to be defined in the first of the columns being joined.
The above mapping would result in the address below for the first example record:
<pre>
  20 London Road, Disney World, London
</pre>

The penultimate column to map is the **postcode** column. Let's assume that the incoming column name is the same as the canonical name and that there is a mapped field **postcode** which benefits from the [Standard YAML mappings](standard-yaml-mappings.md) functionality.

Therefore, the mapping is:

```yaml
- standard_mapping: postcode
```

Finally, the last column to map is **adm_method**, again let's assume that the incoming column name is different to the canonical name **admissionmethod**, therefore we need to define the rawtext_name. There is no mapped field for this data item, so the mapping will simply be:

```yaml
- column: adm_method
  rawtext_name: admissionmethod
```

This is the complete mapping for the example data:
```yaml
- column: prov_code
  rawtext_name: providercode
  mappings:
  - field: providercode
- standard_mapping: surname
- standard_mapping: forenames
  column: forename
- column: dob
  rawtext_name: dateofbirth
  mappings:
  - field: dateofbirth
    format: %d/%m/%Y
- column: addr1
  rawtext_name: address1
  mappings:
  - field: address
    order: 1
    join: ', '
- column: addr2
  rawtext_name: address2
  mappings:
  - field: address
    order: 2
- column: addr3
  rawtext_name: address3
  mappings:
  - field: address
    order: 3
- standard_mapping: postcode
- column: adm_method
  rawtext_name: admissionmethod
```

### Common Gotchas

* Not labelling the correct rawtext_name. Please ensure that the canonical names are used exactly, if you receive a column that isn't listed in the canonical names, please get in touch with your canonical name list maintainer.
* Maintain the indentation of the mapping
