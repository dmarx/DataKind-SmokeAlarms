source('config/misc_variables.r')
source('code/general_purpose/read_csv_to_dt.r')
#load(latest_nfirs_fpath)

countydata    = read_csv_to_dt('data/raw/countydata.csv')
fire_stations = read_csv_to_dt('data/raw/fire_station_census.csv')
installs      = read_csv_to_dt('data/raw/HomeFire_smokeAlarmInstalls.csv')
deaths        = read_csv_to_dt('data/raw/nfirs-deaths.csv')
injuries      = read_csv_to_dt('data/raw/nfirs-injuries.csv')
#incidents    = read_csv_to_dt('data/raw/NFIRS_FireIncidents.csv') # broken
incidents     = read_csv_to_dt('data/raw/NFIRS_FireIncidents_sample.csv')
disaster      = read_csv_to_dt('data/raw/redcross-major-diaster.csv')

sort(names(countydata))
sort(names(fire_stations))

fire_stations[tolower(hq_state)=='md'][c(94,96,97)]
hist(fire_stations[,number_of_stations])
hist(fire_stations[,active_firefighters_career+active_firefighters_volunteer+non_firefighting_volunteer])

fire_stations[order(active_firefighters_career+active_firefighters_volunteer+non_firefighting_volunteer, decreasing=TRUE),]

# Fire stations data is inconsistent. Baltimore: separate record for each station address, but
# staffing numbers (at record level) are department wide. MCFRS gives department wide figures, but then
# SS submits their numbers separately. MCFRS includes volunteer EMTs in their "non_firefighting_volunteer"
# count, but SS does not. Super inconsistent schemes used to complete these forms. Typical fire department.
# Luckily, I doubt we're going to use anything from this particular file.