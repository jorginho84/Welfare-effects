/*
This file computes FE estimates of proximity to mother's labor market outcomes

*/


local user Jorge-server

if "`user'" == "andres"{
	cd 				"/Users/andres/Dropbox/jardines_elpi"
	global db 		"/Users/andres/Dropbox/jardines_elpi/data"
	global codes 	"/Users/andres/Dropbox/jardines_elpi/codes"
}
 
else if "`user'" == "Jorge-server"{
 
  global db "/home/jrodriguezo/childcare/data"
  global codes "/home/jrodriguezo/childcare/codes"
  global results "/home/jrodriguezo/childcare/results"          
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
	
if "`c(username)'" == "Cecilia" {
	global des		"C:\Users\Cecilia\Mi unidad\Uandes\Jardines_elpi"
	global db 		"$des/Data"
	global results 	"$des/Tex/figures_tables"
	global codes 	"C:\Users\Cecilia\Documents\GitHub\Welfare-effects"
}

	if "`c(username)'" == "ccorrea"{
	global des		"G:\Mi unidad\Uandes\Jardines_elpi"
	global db 		"$des/Data"
	global results 	"$des/Tex/figures_tables"
	global codes 	"C:\Users\ccorrea\OneDrive - Universidad de los Andes\Documentos\GitHub\Welfare-effects"
}


clear all
set more off
program drop _all
set seed 100

use "$db/data_estimate", clear

global controls i.m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home




*----------------------*
*---------PREP---------*
*----------------------*

*Below/above median of HH income at baseline
gen cat_income = .
replace cat_income = 1 if percentile_income_h <= 50
replace cat_income = 2 if percentile_income_h > 50 & percentile_income_h != .





/*--------------------------------------------------------------------------------*/
/*----------------   Effects across income       ----------------------------------*/
/*--------------------------------------------------------------------------------*/


*Names for table
local x = 1
foreach names in "earnings (monthly US\$)" "hours worked" "employment (in %)" {
	local name_`x' = "`names'"
	local x = `x' + 1
	
}

local xx = 1
foreach depvar in "wage_18" "hours_w_18" "d_work_18"{
	preserve


	forvalues x = 1/2{
		qui: reghdfe `depvar' min_center_NM $controls if cat_income == `x', absorb(cohort#comuna_cod) vce(robust)
		local beta_takeup_`x' = -_b[min_center_NM]*100
		local ub_takeup_`x' = (-_b[min_center_NM] + _se[min_center_NM]*invnormal(0.975))*100
		local lb_takeup_`x' = (-_b[min_center_NM] - _se[min_center_NM]*invnormal(0.975))*100
			
	}
	
	
	clear
	set obs  3
	gen effects = .
	gen lb = .
	gen ub = .
	replace effects = `beta_takeup_1' if _n == 1
	replace lb = `lb_takeup_1' if _n == 1
	replace ub = `ub_takeup_1' if _n == 1

	replace effects = `beta_takeup_2' if _n == 3
	replace lb = `lb_takeup_2' if _n == 3
	replace ub = `ub_takeup_2' if _n == 3

	egen x = seq()

	twoway (bar effects x, barwidth(1.2) color(black*.7) fintensity(.5)  lwidth(0.4) ) ///
	(scatter effects x, msymbol(circle) mcolor(black*.7) mfcolor(black*.7)) ///
		(rcap ub lb x, lpattern(solid) lcolor(black*.7) ), ///
		ytitle("Effect on `name_`xx''")  xtitle("") legend(off) ///
		xlabel(1 "Low-income" 3 "High-income", noticks) ///
		ylabel(, nogrid)  ///
		graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white))  ///
		plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
		scheme(s2mono) scale(1.7) yline(0, lpattern(dash) lcolor(black))
		*text(1.7 1.6  "Overall effect = `beta_takeup' pp (S.E. = `se_beta_takeup')", place(e) color(blue*.8) size(medsmall)) ///
		

	graph export "$results/`depvar'_low_high.pdf", as(pdf) replace
	
	local xx = `xx' + 1
	
	restore


}



**# Effects across mother educ
label define educ 1 "Less than HS" 2 "HS" 3 "Less than college" 4 "college", modify
label val m_educ educ

gen m_high_school = inlist(m_educ,1,2) 

*Names for table
local x = 1
foreach names in "earnings (monthly US\$)" "hours worked" "employment (in %)" {
	local name_`x' = "`names'"
	local x = `x' + 1
	
}

local xx = 1
foreach depvar in "wage_18" "hours_w_18" "d_work_18"{
// 	local depvar = "wage_18"
	preserve


	forvalues x = 1(-1)0{
		qui: reghdfe `depvar' min_center_NM $controls if m_high_school == `x', absorb(cohort#comuna_cod) vce(robust)
		local beta_takeup_`x' = -_b[min_center_NM]*100
		local ub_takeup_`x' = (-_b[min_center_NM] + _se[min_center_NM]*invnormal(0.975))*100
		local lb_takeup_`x' = (-_b[min_center_NM] - _se[min_center_NM]*invnormal(0.975))*100
			
	}
	
	
	clear
	set obs  3
	gen effects = .
	gen lb = .
	gen ub = .
	replace effects = `beta_takeup_1' if _n == 1
	replace lb = `lb_takeup_1' if _n == 1
	replace ub = `ub_takeup_1' if _n == 1

	replace effects = `beta_takeup_0' if _n == 3
	replace lb = `lb_takeup_0' if _n == 3
	replace ub = `ub_takeup_0' if _n == 3

	egen x = seq()

	twoway (bar effects x, barwidth(1.2) color(black*.7) fintensity(.5)  lwidth(0.4) ) ///
	(scatter effects x, msymbol(circle) mcolor(black*.7) mfcolor(black*.7)) ///
		(rcap ub lb x, lpattern(solid) lcolor(black*.7) ), ///
		ytitle("Effect on `name_`xx''")  xtitle("") legend(off) ///
		xlabel(1 "High-school" 3 "College", noticks) ///
		ylabel(, nogrid)  ///
		graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white))  ///
		plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
		scheme(s2mono) scale(1.7) yline(0, lpattern(dash) lcolor(black))
		*text(1.7 1.6  "Overall effect = `beta_takeup' pp (S.E. = `se_beta_takeup')", place(e) color(blue*.8) size(medsmall)) ///
		

	graph export "$results/`depvar'_meduc_low_high.pdf", as(pdf) replace
	
	local xx = `xx' + 1
	
	restore


}



**# Effects across d_work baseline
egen d_work_baseline = rowmax(d_work_t0*)


*Names for table
local x = 1
foreach names in "earnings (monthly US\$)" "hours worked" "employment (in %)" {
	local name_`x' = "`names'"
	local x = `x' + 1
	
}

local xx = 1
foreach depvar in "wage_18" "hours_w_18" "d_work_18"{
// 	local depvar = "wage_18"
	preserve


	forvalues x = 1(-1)0{
		reghdfe `depvar' min_center_NM $controls if d_work_baseline == `x', absorb(cohort#comuna_cod) vce(robust)
		local beta_takeup_`x' = -_b[min_center_NM]*100
		local ub_takeup_`x' = (-_b[min_center_NM] + _se[min_center_NM]*invnormal(0.975))*100
		local lb_takeup_`x' = (-_b[min_center_NM] - _se[min_center_NM]*invnormal(0.975))*100
			
	}
	
	
	clear
	set obs  3
	gen effects = .
	gen lb = .
	gen ub = .
	replace effects = `beta_takeup_1' if _n == 1
	replace lb = `lb_takeup_1' if _n == 1
	replace ub = `ub_takeup_1' if _n == 1

	replace effects = `beta_takeup_0' if _n == 3
	replace lb = `lb_takeup_0' if _n == 3
	replace ub = `ub_takeup_0' if _n == 3

	egen x = seq()

	twoway (bar effects x, barwidth(1.2) color(black*.7) fintensity(.5)  lwidth(0.4) ) ///
	(scatter effects x, msymbol(circle) mcolor(black*.7) mfcolor(black*.7)) ///
		(rcap ub lb x, lpattern(solid) lcolor(black*.7) ), ///
		ytitle("Effect on `name_`xx''")  xtitle("") legend(off) ///
		xlabel(1 "Employed" 3 "Not employed", noticks) ///
		ylabel(, nogrid)  ///
		graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white))  ///
		plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
		scheme(s2mono) scale(1.7) yline(0, lpattern(dash) lcolor(black))
		*text(1.7 1.6  "Overall effect = `beta_takeup' pp (S.E. = `se_beta_takeup')", place(e) color(blue*.8) size(medsmall)) ///
		

	graph export "$results/`depvar'_work_baseline.pdf", as(pdf) replace
	
	local xx = `xx' + 1
	
	restore


}






