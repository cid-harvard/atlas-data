clear all
set more off

// Author: Muhammed A. Yildirim
// Version: 2.0
// Date: April 24, 2014
// License: BSD License
// Created using Stata/MP 12.1
// This file reads the file created by CEPII and released in BACI dataset.
// Your institution should have access to UN COMTRADE Database to download the BACI dataset.
// Here the dataset was downloaded to "/Users/muhammed/Desktop/Data/BACI/" folder.
// The output will be in "/Users/muhammed/Copy/CEPII/DTA" folder.
// Please run create_country_product_ids.do before this file.

cd "$directory"
local baci "/Users/muhammed/Desktop/Data/BACI"

forvalues year = $initialyear/$finalyear$ {

	display "Started Reading `year'"

	// We use "unar" to unarchive the file downloaded from the website.
	// If you do not have this file installed, please unarchive manually to the folder.
	!unar -f "`baci'/baci92_`year'.rar"
	
	// Read in the unarchived csv file and remove the csv file (it is a big file).
	insheet using "baci92_`year'.csv", clear
	rm "baci92_`year'.csv"
	
	// convert to observatory IDs.
	merge m:1 i using "Support_Files/CEPII_92_country_importer"
	keep if _merge == 3
	drop _merge	
	merge m:1 j using "Support_Files/CEPII_92_country_exporter"
	keep if _merge == 3
	drop _merge
	
	// Generate HS4 code from HS6 code.
	gen commoditycode = floor(hs6/100)
	
	// Collapse the dataset to HS4 level.
	collapse (sum) v, by(origin_id destination_id commoditycode t)
	rename v export_value
	rename t year
	replace export_value = export_value * 1000 // The values are recorded as thousands of dollars, fix it.
	
	// Change the commoditycode to Observatory ID.
	merge m:1 commoditycode using "Support_Files/observatory_hs4.dta"
	keep if _merge == 3
	drop _merge
	drop commoditycode
	order year origin_id destination_id product_id export_value
	
	// Fix some of the known mistakes in the dataset.
	if (`year' == 2008 | `year' == 2009) {
		display "`year'"
		replace export_value = 0 if origin_id == 5 & destination_id == 160 //Eliminate exports from Albania to Nigeria in years 2008 and 2009
	}
	
	// To create the import_value column switch the ids
	preserve
	rename export_value import_value
	rename origin_id temp
	rename destination_id origin_id
	rename temp destination_id
	save temp.dta
	restore
	
	// merge to create the export_value and import_value files
	merge 1:1 year origin_id destination_id product_id using temp.dta
	drop _merge
	replace export_value = 0 if export_value == . // Missing values are indicative of 0 trade.
	replace import_value = 0 if import_value == . // Missing values are indicative of 0 trade.
	rm "temp.dta" // Remove the import value file.
	save "DTA/CEPII_`year'", replace // Save the data.
}
