clear all
set more off
set matsize 5000

// Author: Muhammed A. Yildirim
// Version: 2.0
// Date: April 24, 2014
// License: BSD License
// Created using Stata/MP 12.1
// This file contains the preferred order of running the do files.
// First two lines create the support files used in the next stages.
// Current versions of those files are already provided in the Support_files folder.

// Make sure that you created the DO_Files, Support_files, DTA, Complexity and Atlas Folders before runnig the code.
// And make sure that all the necessary files are present in the DO_Files and Support_files folders.

global directory "/Users/muhammed/Copy/CEPII"
global initialyear 1995
global finalyear 2012

cd "$directory"
*do "DO_Files/pop_gdp_wpi_WDI.do"
*do "DO_Files/create_country_product_ids.do"
do "DO_Files/read_cepii.do"
do "DO_Files/atlas_variables.do"
do "DO_Files/Create_for_observatory.do"
do "DO_Files/merge_complexity.do"
