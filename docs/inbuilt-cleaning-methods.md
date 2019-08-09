---
layout: page
title: Inbuilt Cleaning Methods
permalink: /inbuilt-cleaning-methods/
---

When creating mappings, there are a number of inbuilt cleaning methods (that are provided by the [NdrSupport gem](https://github.com/PublicHealthEngland/ndr_support)).

These methods undertake standard cleaning of data when mapped into a field, with the rawtext value remaining unchanged.

The clean methods are used in an mapping with the following syntax:

```yaml
- column: hosp_no
  rawtext_name: hospitalnumber
  mappings:
  - field: hospitalnumber
    clean: :lpi
```

Below is a list of the clean methods, their functionality and examples:

### **:nhsnumber**

Functionality:
* Removes any non numeric characters
Examples:

|Raw Value|Cleaned Value|
|---|---|
|"  123-456-7890"|"1234567890"|
|"888 888 8888  "|"8888888888"|
|"678-098    9876"|"6780989876"|
|"Quick O\`brown, Fox-38"|"38"|

**Example fields for use**: nhsnumber

### **:lpi**

Funtionality:
* Upcases
* Removes any non aplhanumeric characters
Examples:

|Raw Value|Cleaned Value|
|---|---|
|"rgt9878"|"RGT9878"|
|"   1878785234"|"1878785234"|
|"RGT-786"|"RGT786"|
|"65 78997"|"6578997"|
|"Quick O\`brown, Fox-38"|"QUICKOBROWNFOX38"|

**Example fields for use**: hospitalnumber

### **:hospitalnumber**

Funtionality:

* Removes last character from value if it is not a digit 
Examples:


|Raw Value|Cleaned Value|
|---|---|
|"RGT1223B"|"RGT1223"|
|"746R876"|"746R876"|
|"d4578886C"|"d4578886"|
|"Quick O\`brown, Fox-38"|"Quick O\`brown, Fox-38"|

**Example fields for use**: hospitalnumber

### **:sex**

Functionailty:
* Cleans into consistent format of '1' for male, '2' for female or '0' for not known
Examples:

|Raw Value|Cleaned Value|
|---|---|
|"male"|"1"|
|"FEMALE"|"2"|
|"1"|"1"|
|"2"|"2"|
|"M"|"1"|
|"F"|"2"|
|""|"0"|
|"UNKNOWN"|"0"|
|"unk"|"0"|
|"Quick O\`brown, Fox-38"|"0"|

**Example fields for use**: sex

### **:name**

Functionailty:
* Removes .
* Replaces , or ; with a space.
* Replaces 2 or more spaces with 1 space
* Replaces \` with '
* Removes leading and trailing spaces
Examples:

|Raw Value|Cleaned Value|
|---|---|
|"ollie"|"OLLIE"|
|"O`brian"|"O'BRIAN"|
|"Smith        Jones"|"SMITH JONES"|
|"  67890"|"67890"|
|",,, Potato"|"POTATO"|
|"Thomas h.   "|"THOMAS H"|
|"Quick O\`brown, Fox-38"|"QUICK O'BROWN FOX-38"|

**Example fields for use**: surname, forenames, previoussurname


### **:roman5**

Functionailty:
* Deromanises roman numerals between 1 and 5
Examples:

|Raw Value|Cleaned Value|
|---|---|
|"I"|"1"|
|"5"|"5"|
|"IV"|"4"|
|"iii"|"3"|
|"iiC"|"2C"|
|"IIII-B"|"4-B"|
|"UNKNOWN"|"UNKNOWN"|
|"Quick O\`brown, Fox-38"|"Qu1ck O\`brown, Fox-38"|

### **:code_icd**

Functionality:
* Splits grouped codes by comma, semicolon or space
* Upcases
* ICD code is removed if it is entirely non alphanumeric characters
Examples:

|Raw Value|Cleaned Value|
|---|---|
|"c50.9"|"C50.9"|
|"C61.x, C34.2, --."|"C61.X C34.2"|
|"C14x"|"C14X"|
|"C61.x, C34.2, --."|"C61.X C34.2"|
|"c459;  \~\~; C01.9"|"C459 C01.9"|
|"Quick O\`brown, Fox-38"|"QUICK O\`BROWN FOX-38 "|


**Example fields for use**: primarydiagnoses, otherdiagnoses

### **:code_opcs**

Functionality:
* Splits grouped codes by comma, semicolon or space
* Upcases
* Non alphanumeric characters removed from each code
* Cleaned codes of length < 3 or > 4 are removed
Examples:

|Raw Value|Cleaned Value|
|---|---|
|"X71.9, \~\~, e543"|"X719 E543"|
|"  t-12.4"|"T124 "|
|"Quick O\`brown, Fox-38"|""|

**Example fields for use**: primaryprocedures

### **:postcode**

Functionality:
* Values in a postcode format are upcased and centre padded with space(s) to make it 7 characters long (if required)
* All other values are returned untouched
Examples:

|Raw Value|Cleaned Value|
|---|---|
|"N2[ _space_ ]5zz"|"N2[ _space_ ][ _space_ ]5ZZ"|
|"ZZ32 7rr"|"ZZ327RR"| 
|"W12 8QT "|"W12 8QT"|
|"ab213TT"|"AB213TT"|
|"UNKNOWN"|"UNKNOWN"|
|"Quick O\`brown, Fox-38"|"Quick O\`brown, Fox-38"|

**Example fields for use**: postcode

### :tnmcategory

Functionality:
* Leading 'T', 'N', or 'M' are removed (upper or lowercase)
* Lowercase 'x' is upcased to 'X'
* All other values are downcased
Examples:

|Raw Value|Cleaned Value|
|---|---|
|"T1A"|"1a"|
|"Nx"|"X"|
|"n1"|"1"|
|"x"|"X"|
|"TIS"|"is"|
|"m0"|"0"|
|"Unknown"|"unknown"|
|"Quick O\`brown, Fox-38"|"quick o\`brown, fox-38"| 

### :upcase

Functionality:
* Upcases any raw value
Examples:

|Raw Value|Cleaned Value|
|---|---|
|"c50.9"|"C50.9"|
|"iii"|"III"|
|"Quick O\`brown, Fox-38"|"QUICK O\`BROWN, FOX-38"| 

## Notes:

It's worth noting that some of these fields benefit from the [Standard YAML mappings](standard-yaml-mappings.md) functionality.
