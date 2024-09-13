local user Jorge

if "`user'" == "andres"{
	cd 				"/Users/andres/Dropbox/jardines_elpi"
	global db 		"/Users/andres/Dropbox/jardines_elpi/data"
	global codes 	"/Users/andres/Dropbox/jardines_elpi/codes"
}
 
else if "`user'" == "Jorge-server"{
 
  global db "/home/jrodriguez/childcare/data"
  global codes "/home/jrodriguez/childcare/codes"
  global km "/home/jrodriguez/childcare/data"
  global results "/home/jrodriguez/childcare/results"          
}

else if "`user'" == "Jorge"{
 
  global db "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare/Data"
  global results "/Users/jorge-home/Dropbox/Research/DN-early/Dynamic_childcare/Results"          
}

else if "`user'"=="Antonia"{
	global des "/Volumes/AKAC20/CC/CC_Jardines/Datos-Jardines"
	cd "$des"
	global db "$des/Data"
	global results "$des/resultados-anto/public_34/mprte"


	}

clear all
set more off
program drop _all
set seed 100

use "$db/data_estimate", clear

global controls i.m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home
keep if cohort <= 2010


*----------------------*
*---------PREP---------*
*----------------------*


*Below/above median of HH income at baseline
qui: sum income_t0, d
scalar median_i = r(p50)
gen cat_income = .
replace cat_income = 1 if income_t0 <= median_i
replace cat_income = 2 if income_t0 > median_i & income_t0 != .


sum TVIP_age_2 TVIP_age_3 TVIP_age_4, d



reghdfe TVIP_age_2 min_center_34 $controls , absorb(cohort#comuna_cod) vce(robust)

reghdfe TVIP_age_3 min_center_34 $controls if TVIP_age_2 != ., absorb(cohort#comuna_cod) vce(robust)

reghdfe CBCL_t min_center_34 $controls , absorb(cohort#comuna_cod) vce(robust)

reghdfe CBCL_t min_center_34 $controls if cat_income == 1, absorb(cohort#comuna_cod) vce(robust)

reghdfe CBCL_t min_center_34 $controls if cat_income == 2, absorb(cohort#comuna_cod) vce(robust)

