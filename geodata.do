clear all

local user Jorge-server

if "`user'" == "andres"{
	global db 		"/Users/andres/Dropbox/jardines_elpi/data"
	global codes 	"/Users/andres/Dropbox/jardines_elpi/codes"
	global km		"/Users/andres/Dropbox/jardines_elpi/Data/geodata/Output" //???
}

else if "`user'" == "Jorge-server"{ 
  global db "/home/jrodriguezo/childcare/data"
  global codes "/home/jrodriguezo/childcare/codes"
  global km "/home/jrodriguezo/childcare/data"
}

else if "`user'" == "Jorge"{
	global db "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare/Data"
	global results "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare/Results"
 
     
}

else if "`user'" == "Pablo"{
	cd "C:\Users\Pablo\Dropbox\Datos Jardines Chile"
	global db 		"C:\Users\Pablo\Dropbox\Datos Jardines Chile\Data\ELPI"
	global codes 	"C:\Users\Pablo\Dropbox\Datos Jardines Chile\Do\Códigos ELPI"
	global km		"C:\Users\Pablo\Dropbox\Datos Jardines Chile\Data\geodata\Output"
	global temp		"C:\Users\Pablo\Dropbox\Datos Jardines Chile\Data\ELPI\temp"
}

else if "`user'"=="Antonia"{
	global des "/Volumes/AKAC20/CC/CC_Jardines/Datos-Jardines"
	cd "$des"
	global db "$des/Data"
	global results "$des/resultados-anto"
}

if "`c(username)'" == "ccorrea"{
	global des		"G:\Mi unidad\Uandes\Jardines_elpi"
	cd "$des"
	global db 		"$des/Data"
	global codes 	"C:\Users\ccorrea\OneDrive - Universidad de los Andes\Documentos\GitHub\Welfare-effects"
}


if "`c(username)'" == "Cecilia" {
	global des		"C:\Users\Cecilia\Mi unidad\Uandes\Jardines_elpi"
	global db 		"$des/Data"
	global codes 	"C:\Users\Cecilia\Documents\GitHub\Welfare-effects"
}


set more off

**# (1) Generate distances db: for each elpi_year, we append 15 dbfs (one per region). 
foreach elpi_year in 2010 2012{
forval i = 1/15 {
di "--------------------- ELPI year = `elpi_year'; i = `i' ---------------------"
	import dbase "$db/Dist2020/Distancias_`elpi_year'/D0`i'_`elpi_year'.dbf", clear 
	gen region = `i'
	tempfile d`i'_`elpi_year'
	save `d`i'_`elpi_year''
}
use `d1_`elpi_year''
forval i=2/15 {
	append using `d`i'_`elpi_year''
}
rename InputID folio
rename TargetID  id
rename Distance distancia_establecimiento
save "$db/ELPI`elpi_year'_distances.dta", replace
}

/*
**# (2) Distance to the nearest 34 cc center
use id year fuente cap_ms mat_ms cap_het mat_het using "$db/establecimientos3", clear
drop if fuente == "MINEDUC"

sort id year
by id: replace cap_ms  = cap_ms[_n-1]  if cap_ms[_n] == .
by id: replace cap_het = cap_het[_n-1] if cap_het[_n] == .

gen center_34 = 0
replace center_34 = 1 if mat_ms != 0 & !missing(mat_ms) //303 missing values in mat_ms 
replace center_34 = 1 if cap_ms != 0 & !missing(cap_ms) //# of missing values is now 79
replace center_34 = 1 if cap_het != 0 & !missing(cap_het)
replace center_34 = 1 if mat_het != 0 & !missing(mat_het)

keep if center_34 == 1

tempfile est_aux
save `est_aux'

foreach elpi_year in 2010 2012{
	foreach y in 2006 2007 2008 2009 2010 2011 2012 2013 2014 {	
di "_________________________________________________________________________"
di "- Var= dist_min_; ELPI year= `elpi_year'; year= `y'; Type of center= 34 -"
di "_________________________________________________________________________"
		
	use `est_aux', clear
	keep if year == `y'
	tempfile year`y'
	save `year`y''


	use "$db/ELPI`elpi_year'_distances", clear
	merge m:1 id using `year`y''
	keep if _merge == 3
	drop _merge

di "-- Collapse data to create var dist_min_y`y'_34; ELPI year = `elpi_year' --"
		collapse (min) dist_min_y`y'_34 = distancia_establecimiento, by(folio)
		tempfile min_year`y'
		save `min_year`y''
	}

di "------------ Merge years 2006 to 2014; ELPI year = `elpi_year' --------------"
	use `min_year2006', clear
	forvalues y=2007/2014{
		di "y = `y'"
			merge 1:1 folio using `min_year`y''
			drop _merge
	}
	
di "-------------------- Save db ELPI year = `elpi_year' ------------------"
	save "$db/ELPI_N_Centers_`elpi_year'_34center", replace
// 	save "$db/Auxi/ELPI_N_Centers_`elpi_year'_34center", replace //Esto es para evitar escribir sobre la base inicial, y poder comparar entre ellas (por ahora)
}
*/

**#(2) Distance to the nearest 34 cc center + N centers NM in 1000 & 5000 mt radius
/*Geodata variables by type of center*/
use "$db/establecimientos3", clear

sort id year
bys id: replace cap_sc = cap_sc[_n-1] if cap_sc[_n] == .
bys id: replace cap_ms = cap_ms[_n-1] if cap_ms[_n] == .

use id year fuente cap_ms mat_ms cap_het mat_het using "$db/establecimientos3", clear
drop if fuente == "MINEDUC"

sort id year
by id: replace cap_ms  = cap_ms[_n-1]  if cap_ms[_n] == .
by id: replace cap_het = cap_het[_n-1] if cap_het[_n] == .

gen center_34 = 0
replace center_34 = 1 if mat_ms != 0 & !missing(mat_ms) //303 missing values in mat_ms 
replace center_34 = 1 if cap_ms != 0 & !missing(cap_ms) //# of missing values is now 79
replace center_34 = 1 if cap_het != 0 & !missing(cap_het)
replace center_34 = 1 if mat_het != 0 & !missing(mat_het)

keep if center_34 == 1

tempfile est_aux
save `est_aux'

foreach typec in "34"{

foreach elpi_year in 2010 2012{
	foreach y in 2006 2007 2008 2009 2010 2011 2012 2013 2014 {	

	di "_________________________________________________________________________"
	di "- ELPI year= `elpi_year'; year= `y'; Type of center= 34 -"
	di "_________________________________________________________________________"
				
		use `est_aux', clear
		keep if year == `y'
		tempfile year`y'
		save `year`y''


				use "$db/ELPI`elpi_year'_distances", clear
				merge m:1 id using `year`y''
				keep if _merge == 3
				drop _merge
				
				/*# of centers in a radius*/
			di "-- # of centers in a radius: ELPI year = `elpi_year' --"
				preserve
	 			keep if distancia_establecimiento <= 6000 // En caso de que folio tenga missing en N_centers, deberá imputarse 0.
				foreach k in 1000 5000{
					*N_centers
					by folio, sort: egen N_centers`k'_y`y'_`typec'_aux = count(distancia_establecimiento) if distancia_establecimiento<(`k')
					by folio, sort: egen N_centers`k'_y`y'_`typec' = min(N_centers`k'_y`y'_`typec'_aux)
					by folio, sort: replace N_centers`k'_y`y'_`typec' = 0 if N_centers`k'_y`y'_`typec' == .
				}
				collapse (mean) N_centers1000_y`y'_`typec' N_centers5000_y`y'_`typec', by(folio)
				tempfile N_year`y'
				save `N_year`y''
				restore
				
			di "-- Collapse data to create var dist_min_y`y'_34; ELPI year = `elpi_year' --"
			collapse (min) dist_min_y`y'_34 = distancia_establecimiento, by(folio)
			tempfile min_year`y'
			save `min_year`y''
		
		}




di "------------ Merge years 2006 to 2014; ELPI year = `elpi_year' --------------"
		use `N_year2006', clear
		forvalues y=2007/2014{
			merge 1:1 folio using `N_year`y''
			drop _merge
		}
		tempfile Ns_aux
		save `Ns_aux'
		
	use `min_year2006', clear
	forvalues y=2007/2014{
		di "y = `y'"
			merge 1:1 folio using `min_year`y''
			drop _merge
		}

		*merging distance and #of centers by folio	
		merge 1:1 folio using `Ns_aux'
		drop _merge


di "-------------------- Save db ELPI year = `elpi_year' ------------------"
	save "$db/ELPI_N_Centers_`elpi_year'_34center", replace
// 	save "$db/Auxi/ELPI_N_Centers_`elpi_year'_34center", replace //Esto es para evitar escribir sobre la base inicial, y poder comparar entre ellas (por ahora)
}





/*
*N centros por comuna 
use id year fuente region comuna cap_ms mat_ms cap_het mat_het using "$db/establecimientos3", clear
drop if fuente == "MINEDUC"

sort id year
by id: replace cap_ms  = cap_ms[_n-1]  if cap_ms[_n] == .
by id: replace cap_het = cap_het[_n-1] if cap_het[_n] == .

gen center_34 = 0
replace center_34 = 1 if mat_ms != 0 & !missing(mat_ms) //303 missing values in mat_ms 
replace center_34 = 1 if cap_ms != 0 & !missing(cap_ms) //# of missing values is now 79
replace center_34 = 1 if cap_het != 0 & !missing(cap_het)
replace center_34 = 1 if mat_het != 0 & !missing(mat_het)

keep if center_34 == 1

collapse (count) center_34 (sum) cap_* , by(region comuna year) //Hay muchos JI sin comuna asociada.
*/
