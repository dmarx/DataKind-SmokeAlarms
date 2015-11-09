library(magrittr)
library(data.table)

base_path = "E:/Projects/DataKind/SmokeAlarms/data/robin/"

load(paste0(base_path, "Wmat.Rdata")) # Wmat

#'
#' Data Exploration notes
#'

load(paste0(base_path, "tract_data.Rdata")) # sl - 74101 obs, 270 vars

names(sl)
sum(is.na(sl))/prod(dim(sl)) # 2.45% NA

t(sl[1:3,])

#'
#'
#' Would be great if I could identify the source of this data, or reverse engineer
#' constructing this dataset. Should be pretty clear from the PAWGOV presentation.
#'
#' Need to decode:
#'  * disaster_
#'  * econ_
#'  
#'  What is this?
#'  * civic_socialcohesion_
#'  * civic_relig_ (needs details)
#'  * mhp_rate
#'  
#' Merits specific mention in data dictionary (and/or confirmation that it is what I think):
#'  * civic_romney - percent voted for Romney in 2012
#'  * civic_obama  - percent voted for Obama  in 2012
#'  * demos_lpop   - log_e population
#'  * county_fip   - FIPS code component: http://www.policymap.com/blog/2012/08/tips-on-fips-a-quick-guide-to-geographic-place-codes-part-iii/
#'  * state        - FIPS code component: http://www.policymap.com/blog/2012/08/tips-on-fips-a-quick-guide-to-geographic-place-codes-part-iii/
#'  * tract_fip    - FIPS code component: http://www.policymap.com/blog/2012/08/tips-on-fips-a-quick-guide-to-geographic-place-codes-part-iii/
#'  * base_cbsa    - Core based statistical area
#'  * base_ruca_   - rural urban commuting area
#'  
#'  Potentially sensitive/esoteric data:
#'  * civic_private_
#'  * civic_lprivate_
#'  * civic_appropriation_
#'  * member_
#'  
#' For NFIRS: Use zip code to approximate census tract: http://guides.ucf.edu/c.php?g=78401&p=516944
#' ... wait. Holy shit. We actually have lat/lon data in NFIRS. I need to roll up lat/lon to census tract.
#' * Maybe use census geocoder: https://www.census.gov/geo/maps-data/data/geocoder.html
#' * Better yet: FCC census block conversion API - https://www.fcc.gov/developers/census-block-conversions-api


#' # Red Cross Notes
#' 
#' Low hanging fruit: KNN for neighborhoods that are similar to areas they have case history on,
#' but haven't previously targetted because they don't already have a presence there.
#' 
#' Regions correlate to population, chapters do not. Each region run differently, each has access to 
#' different resources.
#' 
#' Some component of this project should be a mechanism to give feedback on how well chapters are 
#' targetting regions most in need.
#' 
#' Red cross fire response should be indicative of major response. Ordinal breakdown:
#'  misc nfirs < red cross response < injury < death
#' 
#' Trailer parks are a hot topic. No physical address, extemely flammable, limited egress.
#' 
#' CAS = client assistance system: database of fire responses
#' 
#' The "plans made" field in the red cross data might be largely disrespected in data entry. 
#' May be highly inflated.
#' 
#' Red cross cares about "how well they're spending their time." They need to not only
#' visit at risk areas: we want them to be successful. If they don't have any successful installations,
#' what's the point?
#' 
#' Additionaly, would like to rank-order red cross regions based on level of risk
#' 
#' Overall goal: 500k smoke alarm installations/year


#' Let's go crazy and poke around Xianghui's data. This is old though... not sure what may have changed.
#' Theoretically, this should at least contain the full NFIRS dataset. I have a 10K record "sample". Want
#' to move past this.

# Hopefully this doesn't take too long...
load("E:/Projects/DataKind/SmokeAlarms/data/rdata/2015-09-16.RData")
#' Looks like the data_all object is what we need here.

names(data_all)



# Here we go. This is what needs to be geocoded.
data_all[['2010incidentaddress']] %>% 
  names %>%
  tolower %>%
  sort

dim(data_all[['2010incidentaddress']]) # 2221660 17


data_all[['2010fireincident']] %>% 
  names %>%
  tolower %>%
  sort

head(data_all[['2010fireincident']])

data_all[['2010basicincident']] %>% 
  names %>%
  tolower %>%
  sort

head(data_all[['2010basicincident']])

data_all[['2010civiliancasualty']] %>%
  names %>%
  tolower %>%
  sort

dim(data_all[['2010civiliancasualty']]) # 12535 35

tolower(sort(names(data_all[['2010fireincident']])))
dim(data_all[['2010fireincident']]) # 663333 80


###############################3

#' Let's use zcta-tract relationships to assign tracts to zip codes. Where there is a many to one or many to many, use all
#' permutations.
#' 
zcta = read.csv("E:/Projects/DataKind/SmokeAlarms/data/raw/census/zcta_tract_rel_10.txt"
                ,colClasses="character"
                )
zcta   = data.table(zcta)
setnames(zcta, names(zcta), tolower(names(zcta)))

#dim(zcta) # 148897     25
#head(zcta)
names(zcta)

# Sanity check that I can use this how I assume I can
zcta[zcta$ZCTA5=="20815",]

#' Oh baby oh baby.

#' Merge zcta on incident location to associate NFIRS incidents with census
#' tracts.

incident_addr = data.table(data_all[['2010incidentaddress']])
setnames(incident_addr, names(incident_addr), tolower(names(incident_addr)))
incident_zip = incident_addr[,.(fdid, inc_date, inc_no, zip5)]

zcta_tract = zcta[,.(zcta5,tract)] 
setkey(incident_zip, zip5)
setkey(zcta_tract, zcta5)
incident_tract = zcta_tract[incident_zip, allow.cartesian=TRUE]
dim(incident_tract) # 20862783        5

#' Next: extract the target variables from NFIRS (and red cross)
#' ** Consider filtering on following incident types:
#'   * 1 - fire
#'   * 10 - fire, other
#'   * 100 - fire, other
#'   * 11 - structure fire
#'   * 110 - structure fire, other
#'   * 112 Fires in structure other than in a building.
#'   * 113 Cooking fire, confined to container.
#'   * 114 Chimney or flue fire, confined to chimney or flue.
#'   * 12 - fire in mobile property used as a fixed structure
#'   * 120 - fire in mobile property used as a fixed structure, other
#'   * 121 - fire in mobile home used as a fixed residence
#'   * 122 - fire in motor home, camper, recreational vehicle
#'   * 123 - fire in portable building fixed location
#'   * 136 Self-propelled motor home or recreational vehicle.
#'   * 137 Camper or recreational vehicle (RV) fire.


#'  * Civilian injury
#'     - affiliation=1 <-- civilian
#'  * Civilian death
#'     - severity=5 <- death
#'  * Firefighter injury (less interested)
#'  * Firefighter death
#'  * viable Property type


inc_basic = data.table(data_all[['2010basicincident']])
setnames(inc_basic, names(inc_basic), tolower(names(inc_basic)))
inc_basic = inc_basic[,
             .(fdid,
               inc_date,
               inc_no,
               ff_death, 
               oth_death, 
               ff_inj, 
               oth_inj, 
               mixed_use, 
               prop_use,
               inc_type
               )]
dim(inc_basic) # 2221660       9

#'
#' Filter on property use
#' 
table(inc_basic[mixed_use == "40" | mixed_use =="58",.(mixed_use, prop_use)])
inc_basic_filtered = copy(inc_basic)
inc_basic_filtered = inc_basic_filtered[
    mixed_use %in% c(
        '40' # residential
        ,'58' # business and residential
      ) | (
        mixed_use %in% c(
          'NN' # Not mixed use
          ,'00' # other
        ) &
        prop_use %in% c(
          '400' # Residential, other.
          ,'419' # 1 or 2 family dwelling.
          ,'429' # Multifamily dwelling.
          ,'439' # Boarding/rooming house, residential hotels.
          ,'449' # Hotel/motel, commercial.
          ,'459' # Residential board and care.
          ,'460' # Dormitory-type residence, other.
          ,'462' # Sorority house, fraternity house.
          ,'464' # Barracks, dormitory.
          )
      ) | (
      # Add incident types that are suggestive of relevant structure types
      inc_type %in% c(
        '120'  # - fire in mobile property used as a fixed structure, other
        ,'121' # - fire in mobile home used as a fixed residence
        ,'122' # - fire in motor home, camper, recreational vehicle
        ,'123' # - fire in portable building fixed location
        ,'136' # Self-propelled motor home or recreational vehicle.
        ,'137' # Camper or recreational vehicle (RV) fire.
        )
      )]
dim(inc_basic_filtered) # 204300      9


data.frame(table(inc_basic_filtered$inc_type))

#' investigate incidents where there was a civilian injury or death. 
#' We ultimately want incidents where people were not injured/killed as well,
#' but I want to see what incident types are listed for these incidents first.

test = data.frame(table(inc_basic_filtered[oth_inj>0 | oth_death>0, inc_type]))
injury_inc_types = test[test[,2]>0,1]
filter_inc_types = unique(inc_basic_filtered[,inc_type])
setdiff(as.character(injury_inc_types), as.character(filter_inc_types)) # no missing incident types

################################################

# Assign tracts to incidents

### Broken Join ###

setkey(inc_basic_filtered, fdid, inc_date, inc_no)
setkey(incident_tract,     fdid, inc_date, inc_no)

dim(incident_tract)                # 20862783        5
dim(incident_tract[!is.na(tract)]) # 20803063        5

inc_basic_filtered

inc = inc_basic_filtered[incident_tract]
dim(inc_basic_filtered)
dim(inc_basic_filtered[incident_tract])

inc[!is.na(inc_type), .N] # 2037458
inc[is.na(inc_type), .N]  # 18902069
inc[,.N]                  # 20939527

# Let's look at a specific no match record
inc[is.na(inc_type)]
incident_tract[fdid=="0001" & inc_date=="1022010" & inc_no =="0001002"]
inc_basic_filtered[fdid=="0001" & inc_date=="1022010" & inc_no =="0001002"]
inc[fdid=="0001" & inc_date=="1022010" & inc_no =="0001002"]

#' OH right. Duh. Many NA records because I filtered out a ton of incidents.
inc = inc[!is.na(inc_type)]

# I think I'm just doing this backwards. I want all records in 
# inc_basic, not in inc_tract. Duh.
inc2 = incident_tract[inc_basic_filtered]
dim(inc2) # 2037458      12
dim(inc) # yeah totally. This is the way I want to do this.

#' Cleanup
rm(inc_basic_filtered)
rm(incident_tract)
rm(inc_basic)
rm(incident_addr)
rm(incident_tract)
rm(incicdent_tract)
rm(incident_zip)
rm(inc)
rm(inc2)
gc()

#' modularize this process, repeat for all years of data.
nfirst_filtered_tract__workhorse = function(
  inc_basic,
  inc_address
  ){
  # Assert data.table with lowercase field names
  inc_basic = data.table(inc_basic)
  setnames(inc_basic, names(inc_basic), tolower(names(inc_basic)))
  inc_address = data.table(inc_address)
  setnames(inc_address, names(inc_address), tolower(names(inc_address)))

  # Filter Columns
  inc_basic = inc_basic[,
                        .(fdid,
                          inc_date,
                          inc_no,
                          ff_death, 
                          oth_death, 
                          ff_inj, 
                          oth_inj, 
                          mixed_use, 
                          prop_use,
                          inc_type
                        )]
  
  # Filter rows
  inc_basic = inc_basic[
    mixed_use %in% c(
      '40' # residential
      ,'58' # business and residential
    ) | (
      mixed_use %in% c(
        'NN' # Not mixed use
        ,'00' # other
      ) &
        prop_use %in% c(
          '400' # Residential, other.
          ,'419' # 1 or 2 family dwelling.
          ,'429' # Multifamily dwelling.
          ,'439' # Boarding/rooming house, residential hotels.
          ,'449' # Hotel/motel, commercial.
          ,'459' # Residential board and care.
          ,'460' # Dormitory-type residence, other.
          ,'462' # Sorority house, fraternity house.
          ,'464' # Barracks, dormitory.
        )
    ) | (
      # Add incident types that are suggestive of relevant structure types
      inc_type %in% c(
        '120'  # - fire in mobile property used as a fixed structure, other
        ,'121' # - fire in mobile home used as a fixed residence
        ,'122' # - fire in motor home, camper, recreational vehicle
        ,'123' # - fire in portable building fixed location
        ,'136' # Self-propelled motor home or recreational vehicle.
        ,'137' # Camper or recreational vehicle (RV) fire.
      )
    )]
  
  # Associate tracts with incidents
  inc_zip = inc_address[,.(fdid, inc_date, inc_no, zip5)]
  setkey(inc_zip, zip5)
  inc_tract = zcta_tract[inc_zip, allow.cartesian=TRUE]
  
  # Merge tract assignments with incident attributes
  setkey(inc_basic, fdid, inc_date, inc_no)
  setkey(inc_tract, fdid, inc_date, inc_no) 
  inc_tract[inc_basic]
}

# Wrap workhorse function in parent function to ensure garbage collection 
# is accomplished after each call
nfirst_filtered_tract = function(inc_basic, inc_address){
  inc = nfirst_filtered_tract__workhorse(inc_basic, inc_address)
  gc()
  inc
}

names(data_all) # we've really only got two years of data here :(

# 4.43s 
system.time(
  inc2010 <- nfirst_filtered_tract(data_all[['2010basicincident']],
                                  data_all[['2010incidentaddress']])
)

# 10.87 s
system.time(
  inc2011 <- nfirst_filtered_tract(data_all[['2011basicincident']],
                                   data_all[['2011incidentaddress']])
)

inc = rbindlist(list(inc2010, inc2011))
rm(inc2010)
rm(inc2011)
gc()

dim(inc) # 4139054      12
inc
table(inc[,oth_inj + oth_death>0]) / nrow(inc) 
# Less than 2% of incidents resulted in non-FF injury or death. 
# I mean... That's good, but that's a rough class imbalance.

# Let's save this object
save(inc, file="E:/Projects/DataKind/SmokeAlarms/data/rdata/inc.rdata")
