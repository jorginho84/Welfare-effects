/*

This do-file generates graph w/ mean value of min_center_34 by cohort and generates table to decide wich missing values to drop.

*/

clear all
set matsize 800

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
	
	if "`c(username)'" == "Cecilia"{
	global des		"C:\Users\Cecilia\Mi unidad\Uandes\Jardines_elpi"
	cd "$des"
	global db 		"$des/Data"
	global results 	"$des/Tex/figures_tables"
	global codes 	"C:\Users\Cecilia\Documents\GitHub\Welfare-effects"
	global results2 "$codes/Resultados"
}

	if "`c(username)'" == "ccorrea"{
	global des		"G:\Mi unidad\Uandes\Jardines_elpi"
	cd "$des"
	global db 		"$des/Data"
	global results 	"$des/Tex/figures_tables"
	global codes 	"C:\Users\ccorrea\OneDrive - Universidad de los Andes\Documentos\GitHub\Welfare-effects"
	global results2 "$codes/Resultados"
}

set more off

**# Versión 1 del cálculo


use "$db/data_estimate", clear


**# (1) Total datos

tab cohort_school, matcell(A)
mat A = J(11,1,.),A
local j = 1
forval c = 2006/2016{
	mat A[`j',1] = `c'
	local j = `j' +1
}
mat colnames A = "Cohorte" "N"
mat li A

**# (2) Distance to the nearest center at 34
use "$db/data_estimate", clear
drop if min_center_34 == .

mat B = J(11,1,.)
mat colnames B = "N distancia"
local j = 1
forval c = 2006/2016{
	count if cohort_school == `c'
	mat B[`j',1] = r(N)
	local j = `j'+1
}

mat A = A,B
mat li A

**# (3) Public center
use "$db/data_estimate", clear
drop if public_34 == .

mat B = J(11,1,.)
mat colnames B = "N public_34"
local j = 1
forval c = 2006/2016{
	count if cohort_school == `c'
	mat B[`j',1] = r(N)
	local j = `j'+1
}


mat A = A,B
mat li A

**# (4) Work vars
use "$db/data_estimate", clear
foreach var in wage hours_w d_work{
	egen `var'_18=rowmean( `var'_t6 `var'_t7)
}

mat B = J(11,3,.)
mat colnames B = "N wage" "N hours_w" "N d_work"
local k = 1
foreach v of varlist wage_18 hours_w_18 d_work_18{
	di "`v'"
local j = 1
forval c = 2006/2016{
	qui: count if cohort_school == `c' & `v' != .
	mat B[`j',`k'] = r(N)
	local j = `j'+1
}
local k = `k'+1
}

mat A = A,B
mat li A

keep if d_work_18 != .


**# (5) Controls
preserve
global controls m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home
foreach v of varlist $controls{
	drop if `v' == .
}

mat B = J(11,1,.)
mat colnames B = "N controls"
local j = 1
forval c = 2006/2016{
	count if cohort_school == `c'
	mat B[`j',1] = r(N)
	local j = `j'+1
}

mat A = A,B
mat li A
restore

*We dont drop obs that do not have control vars. 

mat C = J(11,8,.)
mat colnames C = "Cohorte" "m_educ" "WAIS_t_num" "WAIS_t_vo" "m_age" "dum_young_siblings" "risk" "f_home"


local j = 1
forval c = 2006/2016{
	mat C[`j',1] = `c'
local k = 2
foreach v of varlist $controls {
di "`v'"
	qui: count if cohort_school == `c' & `v' != .
	mat C[`j',`k'] = r(N)
	local k = `k'+1
}
local j = `j'+1
}

mat li C


**# Test | (2) Distance, (3) public (4) work vars.

keep if min_center_34 != .
keep if public_34 != .
keep if d_work_18 != .
// 0 obs deleted.
egen TVIP = rowmean(TVIP_age_2 TVIP_age_3)

global test TEPSI_t_2010 TVIP_age_2 TVIP_age_3 TVIP CBCL2_t_2012 CBCL2_t_2017 BATTELLE_t_2010 BATTELLE_t_2012 BATTELLE_t_2017 

mat T = J(7,10,.)
mat colnames T = "Cohorte" TEPSI_t_2010 TVIP_age_2 TVIP_age_3 TVIP CBCL2_t_2012 CBCL2_t_2017 BATTELLE_t_2010 BATTELLE_t_2012 BATTELLE_t_2017 

local j = 1
forval c = 2005/2011{
	mat T[`j',1] = `c'
	local k = 2
	foreach v of varlist $test{
	di "`c' `v'"
	qui: count if cohort_school == `c' & `v' != .
	mat T[`j',`k'] = r(N)
	local k = `k'+1
}
local j = `j'+1
}

mat li T

putexcel set "$n_obs/N_obs_nonmissins.xlsx", sheet("Testscores") modify
putexcel B2 = mat(T), colnames 

putexcel set "$n_obs/N_obs_nonmissins.xlsx", sheet("Controls") modify
putexcel B2 = mat(C), colnames 

putexcel set "$n_obs/N_obs_nonmissins.xlsx", sheet("Total") modify
putexcel B2 = mat(A), colnames 


stp






**# Versión 2 del cálculo

use "$db/data_estimate", clear

mat A = [2006,2007,2008,2009,2010,2011]
mat A = A'
mat colnames A = "cohort_school"

//Total
mat B = J(6,1,.)
mat colnames B = "Total"
local j = 1
forval c = 2006/2011{
	qui: count if cohort_school == `c'
	mat B[`j',1] = r(N)
	local j = `j'+1
}
mat A = A,B
mat li A

// min_center_34
drop if missing(min_center_34)
mat B = J(6,1,.)
mat colnames B = "min_center_34"
local j = 1
forval c = 2006/2011{
	qui: count if cohort_school == `c'
	mat B[`j',1] = r(N)
	local j = `j'+1
}
mat A = A,B
mat li A

//Controles y m laboral: "Reporte madre"
foreach v of varlist m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home income_t0 public_34 gender{
	qui: drop if missing(`v')
	di "Var: `v' n obs: `r(N_drop)'"
}
mat B = J(6,1,.)
mat colnames B = "Reporte madre"
local j = 1
forval c = 2006/2011{
	qui: count if cohort_school == `c'
	mat B[`j',1] = r(N)
	local j = `j'+1
}
mat A = A,B
mat li A

**# N obs por test




*Drop if missing
foreach v of varlist m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home income_t0 /*public_34*/ gender{
	qui: drop if missing(`v')
	di "Var: `v' n obs: `r(N_drop)'"
}

foreach v of varlist m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home income_t0 public_34 gender{
	qui: count if missing(`v')
	di "Var: `v' n obs: `r(N)'"
}

drop if min_center_34 == .

*Outcomes
egen TVIP = rowmean(TVIP_age_2 TVIP_age_3)
drop if missing(TVIP)

*Graph.
bys birth_date: egen mean_min_center_34 = mean(min_center_34)
tw
tw (qfit min_center_34 birth_date , sort) //(scatter min_center_34 birth_date , sort), legend(off)


bys birth_date: egen mean_min_center_34 = mean(min_center_34)
tw (line mean_min_center_34 birth_date, sort)


bys cohort_school: egen mean_min_center_34 = mean(min_center_34)
// tw (scatter min_center_34 cohort_school , sort)  (line mean_min_center_34 cohort_school , sort) 

collapse (mean) mean_min_center_34 = min_center_34 (p90) p90_min_center_34 = min_center_34 (p10) p10_min_center_34 = min_center_34, by(cohort_school)

tw (line p10_min_center_34 cohort_school , sort) (line p90_min_center_34 cohort_school , sort)  (line mean_min_center_34 cohort_school , sort) 





























