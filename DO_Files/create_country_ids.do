clear all
set more off

cd "/Users/muhammed/Copy/CEPII"

import excel "/Users/muhammed/Desktop/Data/BACI/country_code_baci92.xlsx", sheet("country_code_baci92.csv") firstrow clear
keep iso3 i
drop if i==.
drop if iso3 == ""
drop if length(iso3) != 3
duplicates drop iso3 i, force
rename id exporter

use "/Users/muhammed/Copy/CEPII/Observatory/observatory_country_cepii.dta", clear
keep id i
rename id origin_id
save "/Users/muhammed/Copy/CEPII/CEPII_92_country_importer", replace
rename origin_id destination_id
rename i j
save "/Users/muhammed/Copy/CEPII/CEPII_92_country_exporter", replace

use iso_atlas, clear
rename exporter iso3
merge 1:m iso3 using "/Users/muhammed/Copy/CEPII/Observatory/observatory_country_cepii.dta"
keep if _merge == 3
keep id iso3
rename id origin_id
drop if iso3 == "SDN"
save obs_atlas, replace

// Creating ISO to ID match from the observatory files
import excel "/Users/muhammed/Copy/CEPII/Observatory/beta_observatory_country.xlsx", sheet("beta_observatory_country.csv") firstrow clear
keep id name_3char
rename name_3char iso
duplicates drop
rename id country_id
save iso_obs_id, replace
