Atlas Data
==========

Repository for data / data processing related to [The Atlas of Economic Complexity](https://github.com/cid-harvard/atlas-economic-complexity).

This file contains the information about how to create the Atlas variables from the World Trade Data reported by Centre d’Etudes Prospectives et d’Informations Internationales (CEPII) in the BACI Dataset.

**Step 1.** Download the files from the Database. The URL for the database is:

[http://www.cepii.fr/CEPII/en/bdd_modele/download.asp?id=1](http://www.cepii.fr/CEPII/en/bdd_modele/download.asp?id=1)

To download the data, you need to have the right credentials (i.e., your institution must be a member of UN COMTRADE).In the download page, we usually download the baci92_XXXX.rar where XXXX indicates the year. This program works only for the consecutive years. Save the rar file(s) in a folder.

**Step 2.** In the `run_codes.do` file, change the variables:

* global directory: The folder that contains DO_Files, Support_files, DTA, Complexity and Atlas folders.

* global initialyear: Initial year of the data

* global finalyear: Final year of the data

Make sure that all the do files and support files are present in DO_Files and Support_files folders, respectively.

List of Do Files:

	run_codes.do
	read_cepii.do
	atlas_variables.do
	Create_for_observatory.do
	create_country_product_ids.do (Not crucial)
	pop_gdp_wpi_WDI.do (Not crucial)

List of Support Files:

	beta_observatory_country.xlsx
	beta_observatory_hs4.xlsx
	CEPII_92_country_exporter.dta
	CEPII_92_country_importer.dta
	country_code_baci92.xlsx
	country_id_population.dta
	country_names.dta
	gdp_gnp_pop_wpi.dta
	hs4_id_community.dta
	iso_atlas.dta
	iso_numeric.txt
	iso_obs_id.dta
	obs_atlas.dta
	observatory_country_cepii.dta
	observatory_hs4.dta

Make sure that you created DTA, Complexity and Atlas folders.

**Step 3.** You can run `pop_gdp_wpi_WDI.do and `create_country_product_ids.do` to create support variables but these are already provided for you in the Support_files folder.

**Step 4.** Next step is to run the `read_cepii.do` file. For the output make sure that you already created “DTA” folder. If you have `unar` installed in your UNIX system, change the `baci` local in the `read_cepii.do` file to the folder that you saved the rar file in. If you do not have “unar”, manually unarchive all the files into the main directory (the one that you define in the run_codes.do). Output of `read_cepii.do` is a dta file stored in DTA folder.

**Step 5.** Next, we run atlas_variables.do file. Main input for this step is the output of `read_cepii.do` file.

**Step 6.** Finally we run Create_for_observatory.do file using the outputs of `read_cepii.do` and `atlas_variables.do`.

