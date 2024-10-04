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
	
	if "`c(username)'" == "Cecilia"{
	global des		"C:\Users\Cecilia\Mi unidad\Uandes\Jardines_elpi"
	cd "$des"
	global db 		"$des/Data"
	global results 	"$des/Tex/figures_tables"
	global codes 	"C:\Users\Cecilia\Documents\GitHub\Welfare-effects"
	global n_obs 	"$des/Numero de observaciones"
}

	if "`c(username)'" == "ccorrea"{
	global des		"G:\Mi unidad\Uandes\Jardines_elpi"
	cd "$des"
	global db 		"$des/Data"
	global results 	"$des/Tex/figures_tables"
	global codes 	"C:\Users\ccorrea\OneDrive - Universidad de los Andes\Documentos\GitHub\Welfare-effects"
	global n_obs 	"$des/Numero de observaciones"
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
// use "$db/data_estimate", clear
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
// use "$db/data_estimate", clear
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
// use "$db/data_estimate", clear
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

putexcel set "$n_obs/N_obs_nonmissins.xlsx", sheet("Total") modify
putexcel B2 = mat(A), colnames 


**# Controles
*We dont drop permanently obs that do not have control vars, so now we count the number of obs of each control var.

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


putexcel set "$n_obs/N_obs_nonmissins.xlsx", sheet("Controls") modify
putexcel B2 = mat(C), colnames 



**# Test | (2) Distance, (3) public (4) work vars.
use "$db/data_estimate", clear

*BATELLE
forval d = 0/11 {
	gen batelle_age`d'_t = BATTELLE_t_2010 if birth_year == 2010 - `d'
	gen batelle_age`d'_ronda = 2010 if batelle_age`d'_t == BATTELLE_t_2010 & batelle_age`d'_t != .
	replace batelle_age`d'_t = BATTELLE_t_2012 if birth_year == 2012 - `d' & batelle_age`d'_t == .
	replace batelle_age`d'_ronda = 2012 if batelle_age`d'_t == BATTELLE_t_2012 & batelle_age`d'_t != .
	replace batelle_age`d'_t = BATTELLE_t_2017  if birth_year == 2017 - `d' & batelle_age`d'_t == .
	replace batelle_age`d'_ronda = 2017 if batelle_age`d'_t == BATTELLE_t_2017 & batelle_age`d'_t != .
// 	label var batelle_age`d'_t "BATTELLE test score at `d' years old"
// 	label var batelle_age`d'_ronda "From wich ELPI year is the BATELLE test score at `d' years old"
}
	
*TVIP
forval d = 0/11 {
	gen tvip_age`d'_t = TVIP_t_2010 if birth_year == 2010 - `d'
	gen tvip_age`d'_ronda = 2010 if tvip_age`d'_t == TVIP_t_2010 & tvip_age`d'_t != .
	replace tvip_age`d'_t = TVIP_t_2012 if birth_year == 2012 - `d' & tvip_age`d'_t == .
	replace tvip_age`d'_ronda = 2012 if tvip_age`d'_t == TVIP_t_2012 & tvip_age`d'_t != .
	replace tvip_age`d'_t = TVIP_t_2017  if birth_year == 2017 - `d' & tvip_age`d'_t == .
	replace tvip_age`d'_ronda = 2017 if tvip_age`d'_t == TVIP_t_2017 & tvip_age`d'_t != .
// 	label var tvip_age`d'_t "TVIP test score at `d' years old"
// 	label var tvip_age`d'_ronda "From wich ELPI year is the TVIP test score at `d' years old"
}

*CBCL1
forval d = 0/11 {
	gen cbcl1_age`d'_t = CBCL1_t_2010 if birth_year == 2010 - `d'
	gen cbcl1_age`d'_ronda = 2010 if cbcl1_age`d'_t == CBCL1_t_2010 & cbcl1_age`d'_t != .
	replace cbcl1_age`d'_t = CBCL1_t_2012 if birth_year == 2012 - `d' & cbcl1_age`d'_t == .
	replace cbcl1_age`d'_ronda = 2012 if cbcl1_age`d'_t == CBCL1_t_2012 & cbcl1_age`d'_t != .
	replace cbcl1_age`d'_t = CBCL1_t_2017  if birth_year == 2017 - `d' & cbcl1_age`d'_t == .
	replace cbcl1_age`d'_ronda = 2017 if cbcl1_age`d'_t == CBCL1_t_2017 & cbcl1_age`d'_t != .
// 	label var cbcl1_age`d'_t "CBCL1 test score at `d' years old"
// 	label var cbcl1_age`d'_ronda "From wich ELPI year is the CBCL1 test score at `d' years old"
}

*CBCL2
forval d = 0/11 {
	gen cbcl2_age`d'_t = CBCL2_t_2012 if birth_year == 2012 - `d'
	gen cbcl2_age`d'_ronda = 2012 if cbcl2_age`d'_t == CBCL2_t_2012  & cbcl2_age`d'_t != .
	replace cbcl2_age`d'_t = CBCL2_t_2017  if birth_year == 2017 - `d' & cbcl2_age`d'_t == .
	replace cbcl2_age`d'_ronda = 2017 if cbcl2_age`d'_t == CBCL2_t_2017 & cbcl2_age`d'_t != .
// 	label var cbcl2_age`d'_t "CBCL2 test score at `d' years old"
// 	label var cbcl2_age`d'_ronda "From wich ELPI year is the CBCL2 test score at `d' years old"
}


*Keep final sample
foreach var in wage hours_w d_work{
	egen `var'_18=rowmean( `var'_t6 `var'_t7)
	keep if `var'_18 != .
}
keep if min_center_34 != .
keep if public_34 != .
keep if d_work_18 != .

foreach v of varlist m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home percentile_income_h public_34 gender{
	qui: drop if missing(`v')
	di "Var: `v' n obs: `r(N_drop)'"
}



mat A = J(11,1,.)
local j = 1
forval c = 2006/2016{
	mat A[`j',1] = `c'
	local j = `j' +1
}

*Batelle
mat T = J(11,12,.)
mat E = J(11,12,.)

local c2 = 1
forval c = 2006/2016{
	forval d = 0/11{
		local d2 = `d' +1
		qui: count if cohort == `c' & batelle_age`d'_t != .
		mat T[`c2',`d2'] = r(N)
		qui: sum batelle_age`d'_ronda if cohort == `c'
		mat E[`c2',`d2'] = r(mean)
	}
local c2 = `c2' +1
}

mat T = A,T
mat T = [.,0,1,2,3,4,5,6,7,8,9,10,11]\T
mat li T
mat E = A,E
mat E = [.,0,1,2,3,4,5,6,7,8,9,10,11]\E
mat li E

putexcel set "$n_obs/N_obs_nonmissins.xlsx", sheet("Batelle") modify

putexcel A2 = "N obs Batelle"
putexcel B2 = mat(T) 
putexcel B2 = "Cohort_school\Age"

putexcel A16 = "Ronda ELPI de la que proviene"
putexcel B16 = mat(E) 
putexcel B16 = "Cohort_school\Age"

*TVIP
mat T = J(11,12,.)
mat E = J(11,12,.)

local c2 = 1
forval c = 2006/2016{
	forval d = 0/11{
		local d2 = `d' +1
		qui: count if cohort == `c' & tvip_age`d'_t != .
		mat T[`c2',`d2'] = r(N)
		qui: sum tvip_age`d'_ronda if cohort == `c'
		mat E[`c2',`d2'] = r(mean)
	}
local c2 = `c2' +1
}

mat T = A,T
mat T = [.,0,1,2,3,4,5,6,7,8,9,10,11]\T
mat li T
mat E = A,E
mat E = [.,0,1,2,3,4,5,6,7,8,9,10,11]\E
mat li E

putexcel set "$n_obs/N_obs_nonmissins.xlsx", sheet("TVIP") modify

putexcel A2 = "N obs TVIP"
putexcel B2 = mat(T) 
putexcel B2 = "Cohort_school\Age"

putexcel A16 = "Ronda ELPI de la que proviene"
putexcel B16 = mat(E) 
putexcel B16 = "Cohort_school\Age"

*CBCL1
mat T = J(11,12,.)
mat E = J(11,12,.)

local c2 = 1
forval c = 2006/2016{
	forval d =  0/11{
		local d2 = `d' +1
		qui: count if cohort == `c' & cbcl1_age`d'_t != .
		mat T[`c2',`d2'] = r(N)
		qui: sum cbcl1_age`d'_ronda if cohort == `c'
		mat E[`c2',`d2'] = r(mean)
	}
local c2 = `c2' +1
}

mat T = A,T
mat T = [.,0,1,2,3,4,5,6,7,8,9,10,11]\T
mat li T
mat E = A,E
mat E = [.,0,1,2,3,4,5,6,7,8,9,10,11]\E
mat li E


putexcel set "$n_obs/N_obs_nonmissins.xlsx", sheet("CBCL1") modify

putexcel A2 = "N obs CBCL1"
putexcel B2 = mat(T) 
putexcel B2 = "Cohort_school\Age"

putexcel A16 = "Ronda ELPI de la que proviene"
putexcel B16 = mat(E) 
putexcel B16 = "Cohort_school\Age"

*CBCL2
mat T = J(11,12,.)
mat E = J(11,12,.)

local c2 = 1
forval c = 2006/2016{
	forval d =  0/11{
		local d2 = `d' +1
		qui: count if cohort == `c' & cbcl2_age`d'_t != .
		mat T[`c2',`d2'] = r(N)
		qui: sum cbcl2_age`d'_ronda if cohort == `c'
		mat E[`c2',`d2'] = r(mean)
	}
local c2 = `c2' +1
}

mat T = A,T
mat T = [.,0,1,2,3,4,5,6,7,8,9,10,11]\T
mat li T
mat E = A,E
mat E = [.,0,1,2,3,4,5,6,7,8,9,10,11]\E
mat li E


putexcel set "$n_obs/N_obs_nonmissins.xlsx", sheet("CBCL2") modify

putexcel A2 = "N obs CBCL2"
putexcel B2 = mat(T) 
putexcel B2 = "Cohort_school\Age"

putexcel A16 = "Ronda ELPI de la que proviene"
putexcel B16 = mat(E) 
putexcel B16 = "Cohort_school\Age"

**# fin

stp





* CBCL 
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



**# Exportar base con folios que no tienen var de m laboral
use "$db/data_estimate", clear

foreach var in wage hours_w d_work{
	egen `var'_18=rowmean( `var'_t6 `var'_t7)
}

gen tiene_dist = min_center_34 != .
gen tiene_d_work = d_work_18 != .
gen tiene_wage = wage_18 != .
gen tiene_public_34 = public_34 != .

keep if inlist(cohort_school,2010,2011) 
keep folio cohort_school cohort tiene*

keep if tiene_dist== 1 & tiene_d_work == 0
save "$db/aux_foliossin_dwork.dta", replace


* Revisamos 2010
use "$db/elpi_original/Cuidado_infantil_2010", clear
rename j1 dum_work 
recode dum_work (2 = 0) (9 = .)
rename orden tramo

merge m:1 folio using "$db/aux_foliossin_dwork.dta"

keep if _m == 3 // Matched   24  (_merge==3): 

keep folio cohort* tramo dum_work tiene*
reshape wide dum_work, i(folio) j(tramo)


* Revisamos 2012
use "$db/elpi_original/Cuidado_infantil_2012" , clear

merge m:1 folio using "$db/aux_foliossin_dwork.dta"

keep if _m == 3
rename e1 dum_work 
recode dum_work (2 = 0) (9 = .)
 

keep folio cohort* tramo dum_work tiene*
reshape wide dum_work, i(folio) j(tramo)



//--> Todos los folios responden hasta tramo = 5. 
/* if _m == 3

     tramo: |
   Tramo de |
       edad |      Freq.     Percent        Cum.
------------+-----------------------------------
  0-3 meses |      1,215       26.51       26.51
  3-6 meses |      1,215       26.51       53.02
 6-12 meses |      1,215       26.51       79.53
12-18 meses |        787       17.17       96.71
18-24 meses |        151        3.29      100.00
------------+-----------------------------------
      Total |      4,583      100.00
*/

use "$db/elpi_original/Hogar_2012", clear
keep if orden == 1

merge 1:1 folio using "$db/aux_foliossin_dwork.dta"
keep if _m == 3

foreach v of varlist k*{
	recode `v' (2 = 0)
}
egen trab = rowmax(k1 k3 k4)

bys cohort_school: tab tiene_d_work trab, m















