************************************************************************
** [Coding Example of Stata]
** Names of Data Files: muni_pop[yyyy].dta ([yyyy]: Year)
** (Municipal Data from 1980 to 2020)
** Variables year id_muni pop
** year: Survey Year
** id_muni: Municipality Code at the Time of the Survey
** pop: Total Population
************************************************************************
**===============================================
** Reaggregation of Past Municipal Data
**===============================================
foreach T in "1980" "2020" {
	** Load Municipal Data
	use "data/muni_pop`T'.dta", clear

	** Make Key Variable to Connect with the Municipality Converter
	gen merge_id_muni = id_muni

	** AddMunicipal Codes and Names as of 2020 using the Key Variable
	merge 1:1 merge_id_muni using "data_converter/municipality_converter_en.dta", keepusing(id_muni2020 name_muni2020)

	** Delete Unused Data in the Data
	drop if _merge == 1

	** Delete Unused Data in the Municipality Converter File
	drop if _merge == 2

	** Reaggregate Past Data using the 2020 Municipal Code
	by id_muni2020, sort: egen totalpop = total(pop)

	** Delete Duplicated Records
	duplicates drop id_muni2020, force

	** Keep Variables to be Used
	keep year id_muni2020 name_muni2020 totalpop

	** Data Formatting
	sort id_muni2020
	order year id_muni2020 name_muni2020 totalpop

	** Store Past Data with Municipality Code as of 2020
	save "data/muni_pop`T'_base2020.dta", replace
}

**===============================================
** Creat Long-style Panel Data
**===============================================
** Delete Data on Memory
clear
** Append Data by Loop
foreach T in "1980" "2020" {
	append using "data/muni_pop`T'_base2020.dta"
}

** Save Panel Data
save "data/muni_pop_panel1980-2020.dta", replace

**===============================================
** Population Growth
**===============================================
** Load Panel Data
use "data/muni_pop_panel1980-2020.dta", clear

** Set Panel Data
xtset id_muni2020 year, yearly

** Make Variables
gen lnpop = log(totalpop)
gen growth_pop = lnpop - L40.lnpop

** Scatter Plot
twoway ///
	(scatter growth_pop L40.lnpop, ms(o)) ///
	(lfit growth_pop L40.lnpop, lw(thick)) ///
	, ///
	ysize(9) ///
	xsize(15) ///
	ylabel(-3(1)2, ang(h) labsize(medlarge) grid gmax gmin) ///
	xlabel(4(2)16, labsize(medlarge) grid gmax gmin) ///
	ytitle("log(Pop. in 2020) - log(Pop. in 1980)", tstyle(size(medlarge))) ///
	xtitle("log(Pop. in 1980)", tstyle(size(medlarge))) ///
	legend(off) ///
	graphregion(color(white) fcolor(white))
graph export "fig/fIG_scatter.eps", fontface("Palatino Linotype") replace
graph export "fig/fIG_scatter.svg", replace



