#'
#' Merge tract-level attributes to incident data.
#'
rm(list = ls())
gc()

load("E:/Projects/DataKind/SmokeAlarms/data/rdata/inc.rdata")

base_path = "E:/Projects/DataKind/SmokeAlarms/data/robin/"
load(paste0(base_path, "tract_data.Rdata")) # sl - 74101 obs, 270 vars
sl = data.table(sl)
setnames(sl, names(sl), tolower(names(sl)))

sort(names(inc))
sort(names(sl))
head(sl$tract_fip)
head(inc$tract) # need to expand this FIP code to include county and state ids  
t(sl[1:3,])

#I think the geoid field in 'sl' had leading zeros stripped. Let's check to 
# make sure there are no inc geoids that won't match to sl geoids.
setdiff(inc[,unique(geoid)], sl[,unique(geoid)]) 
#' just 14. Probably not worth getting worked up about, but also probably
#' not too hard to fix. Need a regex to strip leading zeros.
#' state-county ids: 
#' * 04-019 (AZ) 
#' * 06-037
#' * 36-053 (NY). 
#' * 36-065 (NY).
#' 

setkey(inc, geoid)
setkey(sl, geoid)

if(FALSE){
  inc[setdiff(inc[,unique(geoid)], sl[,unique(geoid)]) , .N]
  # 12929 records
  sum(inc[setdiff(inc[,unique(geoid)], sl[,unique(geoid)]) , oth_inj + oth_death>0])
  # just 74 injury/death incidents. Fuck it, we'll just drop these records. 
  # Maybe fix this later, not worth the trouble.
}

#inc_vars = sl[inc]
#' Woah nelly! This completely fried my computer.
#' Instead of actually merging these two datasets in toto, let's just
#' merge subsets of the data as needed. I.e. we'll accomplish the merge
#' repeatedly from within cross-validation iterations.