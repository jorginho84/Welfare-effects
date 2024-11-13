/*

This do-file generates graph w/ mean value of min_center_34 by cohort and generates table to decide wich missing values to drop.

*/

clear all

if "`c(username)'" == "ccorrea"{
	global des		"G:\Mi unidad\Uandes\Jardines_elpi"
	global db 		"$des/Data"
	global results 	"$des/results"
	global codes 	"C:\Users\ccorrea\OneDrive - Universidad de los Andes\Documentos\GitHub\Welfare-effects"
}

if "`c(username)'" == "Cecilia" {
	global des		"C:\Users\Cecilia\Mi unidad\Uandes\Jardines_elpi"
	global db 		"$des/Data"
// 	global results 	"$des/results"
	global results 	"$des/Tex/figures_tables"
	global codes 	"C:\Users\Cecilia\Documents\GitHub\Welfare-effects"
}

cd "$des"

// -----------------------------------

**# First: all data
use "$db/data_estimate", clear
keep folio dist_min_* birth* /*cohort**/
format birth_date %td

*Change shape of data to long
reshape long dist_min_y2006_34_ dist_min_y2007_34_ dist_min_y2008_34_ dist_min_y2009_34_ dist_min_y2010_34_ dist_min_y2011_34_ dist_min_y2012_34_ dist_min_y2013_34_ dist_min_y2014_34_ , i(folio) j(elpi_year)
rename dist_min_y*_34_ dist_min*
reshape long dist_min , i(folio elpi_year) j(year)

*Collapse data: first to have one obs per elpi_year 
collapse (mean) dist_min, by(folio birth_date birth_year /*birth_month cohort**/ year )

*Variable that shows distance to nearest center at 34.
gen dist_min_34 = dist_min if year >= birth_year +2 & year <= birth_year +4 //Esto para tomar tramos 6 y 7 
// Tramo 6: 2-3 años
// Tramo 7: 3-4 años
// bys folio: egen dist_min_34 = mean(aux_dist_min_34)

*Collapse data: to have one obs per year
collapse (mean) dist_min dist_min_34, by( year )

format dist_min* %9.0g
*Graph
tsset year
tw (tsline dist_min) (tsline dist_min_34) , ylabel(0(500)2000) ytitle("Distance to the nearest center (mt)") xtitle("Year") legend(order(1 "At all ages" 2 "Ages 2 to 4") position(6) c(2))
graph export "$results/meandistance_year.png", as(png) replace

*La desviación estándar es altísima:
// tw (line dist_min year, sort lcolor(blue)) (line lower_b year, lcolor(blue) lpattern(dash)) (line upper_b year, lcolor(blue) lpattern(dash)), legend(off)

/*

**# High vs low income
use "$db/data_estimate", clear
keep folio dist_min_* elegible*

foreach v of varlist elegible* {
	preserve
	di "`v'"
	drop if `v' == .
	*Change shape of data to long
reshape long dist_min_y2006_34_ dist_min_y2007_34_ dist_min_y2008_34_ dist_min_y2009_34_ dist_min_y2010_34_ dist_min_y2011_34_ dist_min_y2012_34_ dist_min_y2013_34_ dist_min_y2014_34_ , i(folio) j(elpi_year)
rename dist_min_y*_34_ dist_min*
reshape long dist_min , i(folio elpi_year) j(year)

	*Collapse data: first to have one obs per elpi_year and then to have one obs per year
collapse (mean) dist_min, by(folio `v' year )
collapse (mean) dist_min (sd) dist_min_sd = dist_min, by( year `v')

format dist_min %9.0g


*Graph
tw (line dist_min year if `v' == 1) (line dist_min year if `v' == 0), ylabel(0(500)2000) ytitle("Distance") xtitle("Year") legend(order(1 "Low-income" 2 "High-income" )) note("Variable: `v'") 
graph export "$results/meandistance_year_`v'.png", as(png) replace
	restore
}


// elegible_p60    float   %9.0g                 Less than percentile 60 of income at 2 years old
// elegible_p80    float   %9.0g                 Less than percentile 80 of income at 2 years old
// elegible        float   %9.0g                 Less than percentile 80 of income

**# High vs low income --> Revisión sd
use "$db/data_estimate", clear
keep folio dist_min_* elegible*

foreach v of varlist elegible* {
	preserve
	local v elegible
	di "`v'"
	drop if `v' == .
	*Change shape of data to long
reshape long dist_min_y2006_34_ dist_min_y2007_34_ dist_min_y2008_34_ dist_min_y2009_34_ dist_min_y2010_34_ dist_min_y2011_34_ dist_min_y2012_34_ dist_min_y2013_34_ dist_min_y2014_34_ , i(folio) j(elpi_year)
rename dist_min_y*_34_ dist_min*
reshape long dist_min , i(folio elpi_year) j(year)

	*Collapse data: first to have one obs per elpi_year and then to have one obs per year
collapse (mean) dist_min, by(folio `v' year )
collapse (mean) dist_min (sd) dist_min_sd = dist_min, by( year `v')

format dist_min %9.0g


*Graph
tw (line dist_min year if `v' == 1) (line dist_min year if `v' == 0), ylabel(0(500)2000) ytitle("Distance") xtitle("Year") legend(order(1 "Low-income" 2 "High-income" )) note("Variable: `v'") 
graph export "$results/meandistance_year_`v'.png", as(png) replace
	restore
}

*/


**# Fig 1, panel b
use "$db/data_estimate", clear

*Keep important variables
keep folio dist_min_* birth*  min_center_34 min_center_NMm min_center_NMM min_center_NM /*cohort**/
format birth_date %td

*Change shape of data to long
reshape long dist_min_y2006_34_ dist_min_y2007_34_ dist_min_y2008_34_ dist_min_y2009_34_ dist_min_y2010_34_ dist_min_y2011_34_ dist_min_y2012_34_ dist_min_y2013_34_ dist_min_y2014_34_ , i(folio) j(elpi_year)
rename dist_min_y*_34_ dist_min*
reshape long dist_min , i(folio elpi_year min*) j(year)

*Collapse data: first to have one obs per elpi_year 
collapse (mean) dist_min, by(folio birth_date birth_year /*birth_month cohort**/ year min* )

*Variable that shows distance to nearest center at NM.
keep if year >= birth_year +2 & year <= birth_year +4 //Esto para tomar tramos 6 y 7 
// Tramo 6: 2-3 años
// Tramo 7: 3-4 años
// bys folio: egen dist_min_34 = mean(aux_dist_min_34)

*Collapse data: to have one obs per year
collapse (mean) dist_min, by( year )

format dist_min* %9.0g
*Graph
tsset year

tw (tsline dist_min, lpattern(solid) lwidth(thick))  , ylabel(0(500)2000, labsize(large)) ///
ytitle("Distance to the nearest center (mt)", size(large)) xtitle("Year", size(large))  ///
xlabel(2008(2)2014, /*noticks*/ labsize(large))  ylabel(, nogrid) /// 
graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white)) ///
plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white)) ///
scheme(s2mono) /*xlabel(2008(2)2013, labsize(large))*/ 
// graph export "$results/meandistance_year_24.png", as(png) replace 
graph export "$results/meandistance_year_24.pdf", as(pdf) replace 







