---
title: Explore AHS raw data
author: Andrew Brooks
date: September 21, 2015
output:
   html_document:
     toc: true
     highlight: zenburn
---
#### Getting setup


```r
library('data.table') # need version 1.9.7 from github (Rdatatable/datatable)
library('knitr')
library('maps') # used for state fips code
library('stringr')

setwd('/Users/ajb/Google Drive/Red Cross/smokealarm')
opts_knit$set(root.dir = '/Users/ajb/Google Drive/Red Cross/smokealarm')
opts_knit$set(warning = F)
```

<!-- ####################################### -->
<!-- ####################################### -->
## Gather and Load AHS Data
<!-- ####################################### -->
<!-- ####################################### -->
This data is downloaded directly from the [Census AHS website here](http://www.census.gov/programs-surveys/ahs/data/2011/ahs-national-and-metropolitan-puf-microdata.html). 
I grabbed [AHS 2011 National and Metropolitan PUF v1.4 CSV](http://www2.census.gov/programs-surveys/ahs/2011/AHS%202011%20National%20and%20Metropolitan%20PUF%20v1.4%20CSV.zip)
Note 2013 AHS survey data is available, but does not contain questions related to smoke alarm installs.  
**Codebook:** This [codebook](http://www.census.gov/content/dam/Census/programs-surveys/ahs/tech-documentation/AHS%20Codebook%202013.pdf) is an essential resource.  
the **tnewhouse** is the primary table we are interested in.  There are supplementary tables which provide information about other topics.


```r
system.time(nh <- fread('data/Census/AHS_2011_PUF/tnewhouse.csv', sep=',', stringsAsFactors=F))
```

```
## 
Read 0.0% of 186448 rows
Read 10.7% of 186448 rows
Read 21.5% of 186448 rows
Read 32.2% of 186448 rows
Read 42.9% of 186448 rows
Read 53.6% of 186448 rows
Read 64.4% of 186448 rows
Read 75.1% of 186448 rows
Read 85.8% of 186448 rows
Read 96.5% of 186448 rows
Read 186448 rows and 909 (of 909) columns from 0.724 GB file in 00:00:15
```

```
##    user  system elapsed 
##  14.429   0.706  15.214
```

```r
#system.time(wt <- fread('data/Census/AHS_2011_PUF/tRepwgt.csv', sep=',', stringsAsFactors=F)
```

<!-- ####################################### -->
<!-- ####################################### -->
## Cleaning Up
<!-- ####################################### -->
<!-- ####################################### -->
function to remove annoying ticks in raw data.  `fread` does not currently support the `quote` argument of `read.csv` :(.


```r
removeFirstLastChar <- function(x, first=1, last=1) {
  substr(x, 2, nchar(x)-1)
}
```

Actually removing annoying ticks in data for variables of interest


```r
nh_vars_char <- c('CONTROL', 'COUNTY', 'STATE', 'DIVISION', 'SMOKE', 'SMOKPWR', 'SPRNKLR', 'BATTERY')
for(i in nh_vars_char) set(nh, j=which(i==names(nh)), value=gsub("'", "", nh[[i]]))
```

Adding state abbreviation


```r
data(state.fips)
sf <- data.table(state.fips)
sf[,STATE:=as.character(fips)]
sf[,STATE:=str_pad(STATE, width=2, side='left', pad='0')]  # for merge
```

Adding state abbrevation with match


```r
nh[,abb:=sf$abb[match(STATE, sf$STATE)]]
```

There are some counties that occur in many states.  Must aggregate by STATE & COUNTY







