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
	global results 	"$des/results"
	global codes 	"C:\Users\Cecilia\Documents\GitHub\Welfare-effects"
}

cd "$des"

// -----------------------------------

**# First: all data
use "$db/data_estimate", clear
keep folio dist_min_* /*birth* cohort**/

*Change shape of data to long
reshape long dist_min_y2006_34_ dist_min_y2007_34_ dist_min_y2008_34_ dist_min_y2009_34_ dist_min_y2010_34_ dist_min_y2011_34_ dist_min_y2012_34_ dist_min_y2013_34_ dist_min_y2014_34_ , i(folio) j(elpi_year)
rename dist_min_y*_34_ dist_min*
reshape long dist_min , i(folio elpi_year) j(year)

*Collapse data: first to have one obs per elpi_year and then to have one obs per year
collapse (mean) dist_min, by(folio /*birth_date birth_month birth_year cohort**/ year )
collapse (mean) dist_min (sd) dist_min_sd = dist_min, by( year )

format dist_min %9.0g
gen lower_b = dist_min - 1.96*dist_min_sd 
gen upper_b = dist_min + 1.96*dist_min_sd 
*Graph
tsset year
tw (tsline dist_min), ylabel(0(500)2000) ytitle("Distance to the nearest center") xtitle("Year")
graph export "$results/meandistance_year.png", as(png) replace

*La desviación estándar es altísima:
tw (line dist_min year, sort lcolor(blue)) (line lower_b year, lcolor(blue) lpattern(dash)) (line upper_b year, lcolor(blue) lpattern(dash)), legend(off)



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


 







