*******************************************************************************
** (C) Keisuke Kondo
** 
** Kondo, Keisuke (2023) "Municipality-level panel data and municipal mergers 
** in Japan," RIETI Technical Paper 23-T-001
*******************************************************************************

**===============================================
** Aggregate Yearly Municipal Data of Population Census
**===============================================
forvalues i = 1980(5)2010 {

	** Load Municipal Data
	use "data_pop/DTA_estat_pop`i'.dta", clear

	** Add Variable
	gen year = `i'

	** Sort by Municipal Code
	sort id_muni

	** Add Variable of Merge Key of the Converter
	gen merge_id_muni = id_muni

    ** Add Panel ID and Municipal Name from the Municipal Converter
	merge 1:1 merge_id_muni using "municipality_converter_en.dta", keepusing(id_muni2015 name_muni2015)

	** Drop Unused Data
	drop if _merge == 1
	
	** Drop Unused Data
	drop if id_muni2015 == .

	** Aggregate Municipal Data by Municipal Code as of 2015
	by id_muni2015, sort: egen totalpop = total(pop), missing
	replace year = `i'
	
	** Drop Duplicated Data
	duplicates drop id_muni2015, force
	
	** Data Formatting
	sort id_muni2015
	keep year id_muni2015 name_muni2015 totalpop

	** Store Municipal Data
	save "data_pop/DTA_estat_pop`i'_base2015.dta", replace
}


**===============================================
** Merge Municipal Panel Data of "Japan's Future Committee" as Answer Data
**===============================================
forvalues i = 1980(5)2010 {

	** Load Municipal Panel Data of "Japan's Future Committee" 
	use "data_pop/DTA_estat_pop`i'_base2015.dta", replace

	** Add Variable of Merge Key
	gen id_muni = id_muni2015

	** Add Variable from Answer Data
	merge 1:1 id_muni using "data_pop/DTA_cao_pop.dta", keepusing(pop`i')
	drop _merge

	** Data Formatting
	rename pop`i' pop
	drop id_muni
	
	** Store Municipal Data
	save "data_pop/DTA_estat_pop`i'_base2015_with_cao.dta", replace
}


**===============================================
** Verify Accurary of the Municipal Panel Data
**===============================================

** Clear All Data
clear

** Construct Long-Type Panel Data by Loop
forvalues i = 1980(5)2010 {
	append using "data_pop/DTA_estat_pop`i'_base2015_with_cao.dta"
}

** Store Municipal Panel Data
save "data_pop/DTA_panel_estat_pop_base2015_with_cao.dta", replace

** Compare population between Originally Aggregated Data and Answer Data
gen diff = round(totalpop) - pop

** List of Municipalities with Differences
browse if diff > 1 | diff < -1 
