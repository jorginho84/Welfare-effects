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

**# Locals
local dist = 0 //= 1 if needing to create "$db/ELPI`elpi_year'_distances.dta" database (Item 1)
local pobl = 0 //= 1 if needing to create "$db/Poblacion_edad23_comuna_cohorte.dta" db (item 3).
*Item 2 is going to run, it does not need any local. 


**# (1) Generate distances db: for each elpi_year, we append 15 dbfs (one per region). 
if `dist' == 1{
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
}

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

*Create 2010 & 2012 db, cc centers Nivel Medio.
local typec = "34"

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
}


**# (3) Create db with number of NM children in each comuna by year
if pobl == 1 {
import excel "$db/Datos Comunales/base-2002-(2014)-comunas_pob-total_base-de-datos.xls", clear firstrow sheet("Base_2002a2020_v2")
rename _all, lower
keep if inrange(edad,2,3)
collapse (sum) a20* , by(comuna edad)

reshape long a, i(comuna edad) j(year)

gen cohort = year - edad
drop year
keep if inrange(cohort,2006,2014) //Muestra ELPI

reshape wide a, i(comuna cohort) j(edad)
rename a* edad*_pobl

egen edadNM_pobl = rowtotal(edad*)

label var edad2_pobl "Poblacion niños/as edad 2"
label var edad3_pobl "Poblacion niños/as edad 3"
label var edadNM_pobl "Poblacion niños/as edad 2 y 3 - Nivel Medio"
rename *_pobl pobl_*
rename comuna comuna_cod

save "$db/Poblacion_edad23_comuna_cohorte.dta", replace
}
