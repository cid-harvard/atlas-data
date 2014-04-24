clear all
set more off
set matsize 5000

cd "/Users/muhammed/Copy/CEPII"

import excel "/Users/muhammed/Copy/CEPII/Observatory/beta_observatory_country.xlsx", sheet("beta_observatory_country.csv") firstrow clear

keep id name name_3char
rename name_3char iso3
rename name name_observatory
save "Observatory/country_names.dta", replace

import excel "/Users/muhammed/Copy/CEPII/Observatory/country_code_baci92.xlsx", sheet("country_code_baci92.csv") firstrow clear
keep iso3 name_english i
rename name_english name
drop if iso3 == ""
duplicates drop
drop if i == 581

merge m:1 iso3 using "Observatory/country_names.dta"
keep if _merge == 3
drop _merge

save "Observatory/observatory_country_cepii.dta", replace

/*
*insheet using "/Users/muhammed/Copy/CEPII/Observatory/beta_observatory_hs4.csv", clear
import excel "/Users/muhammed/Copy/CEPII/Observatory/beta_observatory_hs4.xlsx", sheet("Sheet1") firstrow clear
keep id code
rename code commoditycode
rename id product_id
drop if product_id > 1241
sort commoditycode
save "Observatory/observatory_hs4.dta", replace

import excel "/Users/muhammed/Desktop/Data/BACI/country_code_baci92.xlsx", sheet("country_code_baci92.csv") firstrow clear
keep iso3 name_english i
rename name_english name_observatory
duplicates drop
drop if i == 581
keep if iso3 == ""
*/
