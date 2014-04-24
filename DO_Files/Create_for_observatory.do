clear all
set more off

// Author: Muhammed A. Yildirim
// Version: 2.0
// Date: April 24, 2014
// License: BSD License
// Created using Stata/MP 12.1
// This file creates the files for the Atlas website.

cd "$directory"

/*
Complexity File: country_id product_id year export_value import_value selected rca mcp eci pci oppval oppgain insample distance
cpy: country_id	product_id	year	export_value	import_value	export_rca	distance	opp_gain
cy: country_id	year	eci	eci_rank	oppvalue	population	gdp	gni_pc	leader	magic	pc_constant	pc_current	notpc_constant
*/

// Creating the CPY File
forvalues year = $initialyear/$finalyear {

	display "Started Creating CPY File for `year'"
	use "Complexity/Complexity_`year'", clear
	
	rename rca export_rca
	rename oppgain opp_gain
	
	keep country_id product_id year export_value import_value export_rca distance opp_gain
	order country_id product_id year export_value import_value export_rca distance opp_gain
	
	cap save cpy_temp, replace
	
	if `year' == $initialyear {
		cap save cpy, replace
	}
	else{
		use cpy, clear
		append using cpy_temp
		cap save cpy, replace
	}
	rm "cpy_temp.dta"
}
gen long id = _n
order id
outsheet using "Atlas/hs4_cpy.csv", comma replace


// Creating the CY File
forvalues year = $initialyear/$finalyear {
	
	display "Started Creating CY File for `year'"
	use "Complexity/Complexity_`year'", clear
	
	cap replace oppval = . if oppval == 0
	rename oppval oppvalue
	
	collapse (mean) eci oppvalue (sum) export_value import_value, by(country_id year)

/*	
	merge m:1 country_id using iso_obs_id
	keep if _merge == 3
	drop _merge
*/	
	
	merge 1:1 country_id year using gdp_gnp_pop_wpi
	drop if _merge == 2
	drop _merge
	
	summarize notpc_constant, meanonly
	replace notpc_constant = r(mean)
	
	egen eci_rank = rank(-1*eci), unique
	order country_id year eci eci_rank oppvalue population gdp gni_pc magic pc_constant pc_current notpc_constant
	
	drop export_value import_value
	cap save cy_temp, replace
	
	if `year' == $initialyear {
		cap save cy, replace
	}
	else{
		use cy, clear
		append using cy_temp
		cap save cy, replace
	}
	rm "cy_temp.dta"
}
gen long id = _n
order id
outsheet using "Atlas/hs4_cy.csv", comma replace


// Creating the PY File
forvalues year = $initialyear/$finalyear {

	display "Started Creating PY File for `year'"
	use "Complexity/Complexity_`year'", clear
	
	*py: product_id	year	pci	pci_rank	world_trade
		
	collapse (mean) pci (sum) export_value import_value, by(product_id year)
	
	rename export_value world_trade
	drop import_value
	egen pci_rank = rank(-1*pci), unique
	
	order product_id year pci pci_rank world_trade
	cap save py_temp, replace
	
	if `year' == $initialyear {
		save py, replace
	}
	else{
		use py, clear
		append using py_temp
		cap save py, replace
	}
	rm "py_temp.dta"
}
gen long id = _n
order id
outsheet using "Atlas/hs4_py.csv", comma replace


// Creating the CPY File
forvalues year = $initialyear/$finalyear {
	display "Started Creating CCPY File for `year'"
	if `year' == $initialyear {
		use "DTA/CEPII_`year'", clear
	}
	else{
		append using "DTA/CEPII_`year'"
	}
}
*cap save ccpy, replace
gen long id = _n
order id
outsheet using "Atlas/hs4_ccpy.csv", comma replace
