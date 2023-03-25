# The `gitktti` project *- by R&Oslash;BU&trade;*

The `gitktti` scripts are provided to help developers safely use git flow. So powerful...
>**r&oslash;bu:** Yes so powerful!

## Table of contents

- [The `gitktti` project *- by RØBU™*](#the-gitktti-project---by-røbu)
  - [Table of contents](#table-of-contents)
  - [Installation](#installation)
  - [Releases](#releases)
    - [Release 1.0.1 - 25/03/2023](#release-101---25032023)
    - [Release 1.0.0 - 23/03/2023](#release-100---23032023)

## Installation

I recommend to create these aliases:

```bash
alias kfeat='....../gitktti_fix.pl --mode feature'
alias kreal='....../gitktti_fix.pl --mode release'
alias kprune='...../gitktti_fix.pl --prune'
alias kfix='......./gitktti_fix.pl'
alias kfixend='..../gitktti_fixend.pl'
alias ktag='......./gitktti_tag.pl'
alias kco='......../gitktti_checkout.pl'
```

You need to set following environment variable:

```text
export PERL5LIB=..../gitktti/modules
```

***

## Releases

### Release 1.0.1 - 25/03/2023

- NEW FEATURES:
  - **kprune:** added possibility to delete local branches

### Release 1.0.0 - 23/03/2023

- NEW FEATURES:
  - **gitktti:** forked from top secret project: `git_catti (v6.14)`
