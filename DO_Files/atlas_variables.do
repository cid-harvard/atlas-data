clear all
set more off
set matsize 5000

// Author: Muhammed A. Yildirim
// Version: 2.0
// Date: April 24, 2014
// License: BSD License
// Created using Stata/MP 12.1
// This file generates the Complexity Variables, namely Economic Complexity Index (ECI),
// Product Complexity Index (PCI), Complexity Outlook Index (OPPVAL) and Complexity
// Outlook Gain (OPPGAIN).
// Please run read_cepii.do before this file.

cd "$directory"

********************************************************************************
* RCA and RPOP thresholds and the complex country
local rca 1
local rpop 2
local complex_id 105
********************************************************************************

tempvar touse complex_country

forvalues year = $initialyear/$finalyear {

	display "Started Calculating  Atlas Variables for `year'"
	
	// Use the CEPII file in Stata format.
	use "DTA/CEPII_`year'", clear
	
	// Create country and export file from the CEPII file.
	collapse (sum) export_value import_value, by(origin_id product_id year)
	order year origin_id product_id export_value
	
	// FIll-in all country-product combinations.
	fillin year origin_id product_id
	replace export_value = 0 if export_value == .
	replace import_value = 0 if import_value == .
	drop _fillin
	
	// Merge with obs_atlas file to generate the list of selected countries.
	merge m:1 origin_id using "Support_Files/obs_atlas"
	keep if _merge ~= 2
	gen selected = (_merge == 3)
	drop _merge iso3
	
	// Add the population of the countries to the dataset
	merge m:1 origin_id year using "Support_Files/country_id_population"
	drop if _merge == 2
	replace population = 0 if population == .
	drop _merge
	
	// Create the output fields.
	quietly{
		gen rca = .
		gen rpop = .
		gen byte mcp = .
		gen density = .
		gen eci = .
		gen pci = .
		gen oppval = .
		gen oppgain = .
		gen byte insample = .
	}
	
	// Create touse variable for loading the data into MATA.
	cap gen byte `touse' = (export_value!=.)
	
	// Figure out the number of countries and number of products from the data.
	quietly levelsof origin_id if `touse'==1, local(LOCATION)
	quietly levelsof product_id if `touse'==1, local(PRODUCT)	
	global Nc: word count `LOCATION' 
	global Np: word count `PRODUCT'

	// Create MATA variables for number of countries and 		
	mata Ncx=strtoreal(st_global("Nc"))
	mata Npx=strtoreal(st_global("Np"))
	
	// Load the export value for all countries.
    mata exp_long=st_data(.,"export_value", "`touse'") // loads export_values of export/production into the matrix in long format 
	mata exp_cp = rowshape(exp_long,Ncx)  // reshape the data into a rectangular matrix
	
	// Load the export value for all countries.
	mata sel_long=st_data(.,"selected", "`touse'") // loads selected countries into the matrix in long format 
	mata sel_cp = rowshape(sel_long,Ncx)  // reshape the data into a rectangular matrix
	
	// Load the population 
	mata scale_long=st_data(.,"population", "`touse'") // loads values of population into the matrix in long format 
	mata scale_c = rowshape(scale_long,Ncx)  // reshape the data into a rectangular matrix
	
	// Keep tarck of the complex country to correct the sign of ECI. 
	cap gen byte `complex_country' = (origin_id == `complex_id')
	mata exp_long = st_data(.,"`complex_country'", "`touse'") // keeps track of the complex country to cerrect the sign of ECI (a matrix in long format).
	mata Complex_Country = rowshape(exp_long,Ncx)  // reshape the data into a rectangular matrix
	
	display "Finished uploading data to MATA"
	
	// Eliminate the countries that are not selected from some of the matrices.
	mata eliminator = I(Ncx)
	mata zero_elements = sel_cp * J(Npx,1,1)		
	mata eliminator = select(eliminator, zero_elements)
	mata exp_sel_cp = eliminator * exp_cp
	mata scale_sel = eliminator * scale_c
	mata Ncs = rows(exp_sel_cp) // Number of selected countries
	
	// Eliminate some of the products that are not present in the selected countries.
	mata eliminatory = I(Npx)
	mata zero_elements = (J(1,Ncs,1)* exp_sel_cp)'		
	mata eliminatory = select(eliminatory, zero_elements)
	mata exp_sel_cp = exp_sel_cp*eliminatory'
	mata scale_sel = scale_sel*eliminatory'
	mata Complex_Country = Complex_Country*eliminatory'
	mata exp_cp = exp_cp*eliminatory'
	mata scale_c = scale_c*eliminatory'
	mata Nps = rows(exp_sel_cp')
	
	// Update the complex country accordingly.
	mata Complex_Country = Complex_Country * J(Nps,1,1)
	
	display "Finished eliminating zeroes"
	
	// calculations of rca for both selected and all countries.
	// First for the selected countries
	mata exp_tot = sum(exp_sel_cp)		
	mata exp_p = J(Ncs,Ncs,1) * exp_sel_cp 	
	mata exp_c = exp_sel_cp * J(Nps,Nps,1)		 						
	mata RCA = (exp_sel_cp:/exp_c):/(exp_p:/exp_tot)
	// Then for all countries		
	mata exp_p_all = J(Ncx,Ncs,1) * exp_sel_cp 	
	mata exp_c_all = exp_cp * J(Nps,Nps,1)		 						
	mata RCA_all = (exp_cp:/exp_c_all):/(exp_p_all:/exp_tot) 
	
	display "Finished calculating RCAs"
	
	// First calculate M1 which uses RCA larger than threshold
	mata M1 = (RCA:>`rca')
	mata M1_all  = (RCA_all:>`rca')
	
	// Start creating the RSCALE variable
	// First for the selected countries
	mata scale_zero = (scale_sel :> 0)
	mata exp_sel_nonzero_cp = scale_zero:* exp_sel_cp
	mata scale_tot = sum(scale_c)/Nps
	mata scale_sel = (1 :- scale_zero) + scale_sel
	mata RSCALE = (exp_sel_nonzero_cp:/exp_p):/(scale_sel:/scale_tot)
	// Then for all countries
	mata scale_zero = (scale_c :> 0)
	mata exp_nonzero_cp = scale_zero:* exp_cp
	mata scale_c = (1 :- scale_zero) + scale_c
	mata RSCALE_all = (exp_nonzero_cp:/exp_p_all):/(scale_c:/scale_tot)
	
	// Create M2 matrix that indicates which countries have proudcts higher than the threshold.
	mata M2 = (RSCALE:>`rpop') 
	mata M2_all = (RSCALE_all:>`rpop')
	
	// Final MCP matrix indicates the products whether either M1 or M2 are 1.
	mata M = M1 + M2 
	mata M = (M:>0)	
	mata M_all = M1_all + M2_all 
	mata M_all = (M_all:>0)
	
	// Calculate Ubiquity of the produtcs (kp0) and the diversity of the countries (kc0).
	mata kc0 = M*J(Nps,Nps,1) 
	mata kp0 = J(Ncs,Ncs,1)* M
	mata kc0_all = M_all*J(Nps,Nps,1)
	
	// Create the matrix that defines the method of reflections.
	mata Mptilde=((M:/kp0):/kc0)'*M
	mata eigensystem(Mptilde,Vp=.,lp=.) // Solve for the egigenvector of the matrix.
	mata kp=Re(Vp[.,2]) 			// PCI: second eigenvector of the matrix
	mata kc = (M_all:/kc0_all) * kp // ECI: Avergae of the PCI.
	
	// Make sure that the sign of ECI is correct by checking the sign of the ECI for the complex country.
	mata eigensign = 2*((Complex_Country' * kc) > 0 ) - 1
	mata kp = eigensign :* kp
	mata kc = eigensign :* kc
	
	// Convert ECI and PCI into matrices to be used in the calculations.
	mata kc = kc*J(1,Nps,1)
	mata kp1d = kp
	mata kp = J(Ncx,1,1)*kp'
	
	display "Finished calculating eigenexport_values"
	
	// Proximity calculations
    mata C = M'*M
	mata S = J(Nps,Ncs,1)*M
    mata P1 = C:/S
    mata P2 = C:/S'    
    mata proximity = (P1+P2 - abs(P1-P2))/2 - I(Nps)
    
    display "Finished calculating proximity"
    
    // Density
    mata density = ((M_all*proximity):/(J(Ncx,Nps,1)*proximity)) //:*(J(Ncx,Nps,1) - M_all)
    
    // Complexity Outlook Index
    mata opportunity_value = ((density:*(J(Ncx,Nps,1) - M_all)):*kp)*J(Nps,Nps,1)
    
    // Complexity Outlook Gain
    *mata opportunity_gain = (J(Ncx,Nps,1) - M_all):*((J(Ncx,Nps,1) - M_all) * (proximity :* ((kp1d:/(proximity*J(Nps,1,1)))*J(1,Nps,1))) - (density:*(J(Ncx,xNps,1) - M_all)):*kp)
    mata opportunity_gain = (J(Ncx,Nps,1) - M_all):*((J(Ncx,Nps,1) - M_all) * (proximity :* ((kp1d:/(proximity*J(Nps,1,1)))*J(1,Nps,1))))
    
    display "Finished calculating complexity variables"
    
    // Storing the data in matrix form into variables.
	mata insample = J(Ncx,Nps,1)
	*mata insample = eliminator'* insample  * eliminatory
	mata insample = insample  * eliminatory
	mata insample_long=vec(insample') // rca
	mata st_store(.,"insample", "`touse'", insample_long)
	
	display "Finished storing insample"
	
	//mata RCA = eliminator'* RCA
	mata RCA_all = RCA_all  * eliminatory
	mata rca_long=vec(RCA_all') // rca
	mata st_store(.,"rca", "`touse'", rca_long)
	//replace rca = . if insample == 0
	display "Finished storing RCA"
	
	mata RSCALE_all = RSCALE_all  * eliminatory
	mata rpop_long=vec(RSCALE_all') // rca
	mata st_store(.,"rpop", "`touse'", rpop_long)
	//replace rca = . if insample == 0
	display "Finished storing RPOP"
	
	mata M_all = M_all * eliminatory
	mata m_long=vec(M_all') // rca
	mata st_store(.,"mcp", "`touse'", m_long)
	cap replace mcp = . if insample == 0
	display "Finished storing Mcp"
	
	mata density = density  * eliminatory
	mata density_long=vec(density')
	mata st_store(.,"density", "`touse'", density_long)
	cap replace density = . if insample == 0
	display "Finished storing density"
	
	mata kc = kc * eliminatory
	mata kc_long=vec(kc')
	mata st_store(.,"eci", "`touse'", kc_long)
	cap replace eci = . if insample == 0
	display "Finished storing eci"
	
	mata kp = kp * eliminatory
	mata kp_long=vec(kp')
	mata st_store(.,"pci", "`touse'", kp_long)
	cap replace pci = . if insample == 0
	display "Finished storing pci"
	
	mata opportunity_value = opportunity_value * eliminatory
	mata oppval_long=vec(opportunity_value')
	mata st_store(.,"oppval", "`touse'", oppval_long)
	cap replace oppval = . if insample == 0
	display "Finished storing oppval"
	
	mata opportunity_gain = opportunity_gain * eliminatory
	mata oppgain_long=vec(opportunity_gain')
	mata st_store(.,"oppgain", "`touse'", oppgain_long)
	cap replace oppgain = . if insample == 0
	display "Finished storing oppgain"
	
	display "Finished storing data"
	
	// Renormalize ECI and PCI such that mean of ECI is 0 its standard deviation is 1.
	tempvar aux1 aux2
	egen `aux1' = sd(eci), by (`t')
	egen `aux2' = mean(eci), by (`t')
	replace eci = (eci-`aux2')/`aux1'
	replace pci = (pci-`aux2')/`aux1'
	replace oppgain = oppgain/`aux1'
	drop `aux1' `aux2'
	
	// Normalize OPPVAL to have mean of 0 and standard deviation of 1.
	egen `aux1' = sd(oppval), by (`t')
	egen `aux2' = mean(oppval), by (`t')
	replace oppval = (oppval-`aux2')/`aux1'
	drop `aux1' `aux2'
	
	// Drop the temporary variables
	drop `touse' `complex_country'
	display "Finished normalizing variables"
	
	// Use distance instead of density.
	gen distance = 1 - density
	drop density
	
	// change the variable names and order to match the Observatory files.
	rename origin_id country_id
	order country_id product_id year export_value import_value
	
	save "Complexity/Complexity_`year'", replace
}
