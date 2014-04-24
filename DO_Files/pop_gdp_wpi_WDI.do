clear all
set more off

// Author: Muhammed A. Yildirim
// Version: 2.0
// Date: April 24, 2014
// License: BSD License
// Created using Stata/MP 12.1
// This file creates the population, GDP and Wholesale Price Index variables used
// in the calculations and also reported in the Atlsa.

cd "$directory"
local wdifile "/Users/muhammed/Desktop/CID/WDI/WDI_current"
local base_year 2010  // Change the constant year here.

// Creating the fields used from WDI in the Observatory
use "`wdifile'", clear
keep year iso fp_wpi_totl // Keep the Wholesale Price Index (WPI)
keep if iso == "USA" // Keep WPI only for the USA
drop iso
drop if fp_wpi_totl == .
rename fp_wpi_totl wpi
save "Support_Files/year_wpi", replace // Create the year WPI file.

use "`wdifile'", clear
// Keep GDP (PP constant), GNIpc (PP constant) and population fields from WDI.
keep year iso ny_gdp_mktp_kd ny_gnp_pcap_kd sp_pop_totl
rename ny_gdp_mktp_kd gdp
rename ny_gnp_pcap_kd gni_pc
rename sp_pop_totl population
replace iso = "ROU" if iso == "ROM" // Romania is listed differently in Observatory and WDI

// Creating the auxillary variables to estimate the population of countries for missing years
egen idc=group(iso)
summarize idc
local idcmax=r(max)
gen year2=year^2
gen year3=year^3
gen logpop=ln(population)

//Run a regression for each country separetely to estimate the missing values.
forval i=1/`idcmax' {
   quietly {
   cap reg logpop year year2 year3 if idc==`i' // Run the regression using a polynomial for population
   cap predict yhat
   cap replace population = exp(yhat) if idc==`i' & population == . // Replace the missing values with predicted values
   cap drop yhat
   }
}
drop idc year2 year3 logpop // Drop the auxillary variables/

// Convert to Observatory IDs
merge m:1 iso using "Support_Files/iso_obs_id" // Merge with Observatory IDs
keep if _merge == 3
drop _merge

// Merge with Wholesale Price Index of the US.
merge m:1 year using "Support_Files/year_wpi" // Merge the WPI
drop _merge

// To cauclate the conversion factor (i.e., the magic number), we need to decide the base year.
summarize wpi if year == `base_year', meanonly
scalar wpi`base_year' = r(mean)

gen magic = (wpi`base_year'/wpi)/population // Renormalize WPI around the base year and calculate amgic numbers to convert to constant PC
gen pc_constant = magic // To convert to per capita constant dollars, just multiply with the magic number.
gen pc_current = 1/population // To convert to per capita current dollars, just divide by population.
gen notpc_constant = (wpi`base_year'/wpi) // to convert to constant dollars, just divide by teh WPI.
drop wpi iso
order year country_id
sort year country_id
save "Support_Files/gdp_gnp_pop_wpi", replace // Save the file for future use.
rm "Support_Files/year_wpi.dta"

// Create a population file to use in the Complexity Calculations.
keep year country_id population
rename country_id origin_id
save "Support_Files/country_id_population", replace // Save the file for future use.
