clear all
set more off

// Author: Muhammed A. Yildirim
// Version: 2.0
// Date: April 24, 2014
// License: BSD License
// Created using Stata/MP 12.1
// This file generates the ID match between teh Observatory and CEPII.

cd "$directory"

********************************************************************************
********************************************************************************
* This part of the code creates the ID match between the codes
* used in the observatory and codes used by CEPII.
********************************************************************************

import excel "Support_Files/beta_observatory_country.xlsx", sheet("beta_observatory_country.csv") firstrow clear
keep id name name_3char
rename name_3char iso3
rename name name_observatory
save "Support_Files/country_names.dta", replace
import excel "Support_Files/country_code_baci92.xlsx", sheet("country_code_baci92.csv") firstrow clear
keep iso3 name_english i
rename name_english name
drop if iso3 == ""
duplicates drop
drop if i == 581
merge m:1 iso3 using "Support_Files/country_names.dta"
keep if _merge == 3
drop _merge
save "Support_Files/observatory_country_cepii.dta", replace


********************************************************************************
********************************************************************************
* This part of the code creates the IDs used while reading the CEPII files.
********************************************************************************

use "Support_Files/observatory_country_cepii.dta", clear
keep id i
rename id origin_id
save "Support_Files/CEPII_92_country_importer", replace
rename origin_id destination_id
rename i j
save "Support_Files/CEPII_92_country_exporter", replace


********************************************************************************
********************************************************************************
* This part of the code creates the IDs for the selected countries used
* while calculating the Complexity variables.
********************************************************************************

use "Support_Files/iso_atlas", clear
rename exporter iso3
merge 1:m iso3 using "Support_Files/observatory_country_cepii.dta"
keep if _merge == 3
keep id iso3
rename id origin_id
drop if iso3 == "SDN"
save "Support_Files/obs_atlas", replace


********************************************************************************
********************************************************************************
* Creating ISO to ID match from the observatory files
********************************************************************************

import excel "Support_Files/beta_observatory_country.xlsx", sheet("beta_observatory_country.csv") firstrow clear
keep id name_3char
rename name_3char iso
duplicates drop
rename id country_id
save "Support_Files/iso_obs_id", replace


********************************************************************************
********************************************************************************
* Creating a matching file between ID file used in the Observatory and HS4 codes
********************************************************************************

import excel "Support_Files/beta_observatory_hs4.xlsx", sheet("Sheet1") firstrow clear
keep id code
rename code commoditycode
rename id product_id
drop if product_id > 1241
sort commoditycode
save "Support_Files/observatory_hs4.dta", replace


