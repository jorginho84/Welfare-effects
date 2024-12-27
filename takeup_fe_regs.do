/*
This do-file computes distribution of take-up

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
  global codes "/Users/jorge-home/Library/CloudStorage/Dropbox/Research/DN-early/Dynamic_childcare/Codes"
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



egen TVIP = rowmean(TVIP_age_2 TVIP_age_3)




/*---Relevance check---*/ 
// 1.5 qué percentil es? en N de datos
// Para explicar que la estimación es más ruidosa.

qui xi : reghdfe min_center_NM  $controls, absorb(cohort#comuna_cod) resid
predict min_u_34, residuals

foreach perc in 95 90 80 {
	di `perc'
_pctile min_center_NM, p(`perc')
local pctile = r(r1)


twoway (histogram min_center_NM if min_center_NM <= `pctile', lwidth(medium) lcolor(blue) fcolor(blue*.4) yaxis(1)) ///
	(lpolyci public_34 min_u_34 if min_u_34 <= `pctile' & min_u_34>0, degree(1) 	///
	 ciplot(rline)  lpattern(solid)   alcolor(black) alpattern(dash) clwidth(thick)  yaxis(2)), ///
	 ytitle("Frequency") ytitle("Pr(Child care)",axis(2))  xtitle("Kms to closest center") ///
	 legend(off)  ///
	 xlabel(#3, noticks)  xsc(r(0 `pctile')) ylabel(, nogrid) /// 
	 graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white)) ///
	 plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white)) ///
	 scheme(s2mono) scale(1.1)

graph export "$results/take-up_fes_perc`perc'.pdf", as(pdf) replace
}
/*
*Figure: Take-up effects
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
	ytitle("Effect on take-up (in %)")  xtitle("") legend(off) ///
	xlabel(1 "Low-income" 3 "High-income", noticks) ///
	ylabel(, nogrid)  ///
	text(1.7 1.6  "Overall effect = `beta_takeup' pp (S.E. = `se_beta_takeup')", place(e) color(blue*.8) size(medsmall)) ///
	graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white))  ///
	plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
	scheme(s2mono) scale(1.2) yline(0, lpattern(dash) lcolor(black))
	

graph export "$results/take-up_low_high.pdf", as(pdf) replace
*/

**# Utilizando variable percentile_income_h
*-----------------------------------------------------------------

use "$db/data_estimate", clear

global controls i.m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home


foreach corte in 30 40 50 60 80 {
	gen cat_income = .
	replace cat_income = 1 if percentile_income_h <= `corte'
	replace cat_income = 2 if percentile_income_h > `corte' & percentile_income_h != .
// 30 40 50 60 80 distintos cortes para ver si al diferencia marca el efecto.

forvalues x = 1/2{
	qui: reghdfe public_34 min_center_NM $controls if cat_income == `x', absorb(cohort#comuna_cod) vce(robust)
	local beta_takeup_`x' = -_b[min_center_NM]*100
	local ub_takeup_`x' = (-_b[min_center_NM] + _se[min_center_NM]*invnormal(0.975))*100
	local lb_takeup_`x' = (-_b[min_center_NM] - _se[min_center_NM]*invnormal(0.975))*100
		
}


*Overall
qui: reghdfe public_34 min_center_NM $controls, absorb(cohort#comuna_cod) vce(robust)
local beta_takeup = string(round(-_b[min_center_NM]*100,.1),"%9.1f")
local se_beta_takeup = string(round(_se[min_center_NM]*100,.1),"%9.1f")



*By income
forvalues x = 1/2{
	qui: reghdfe public_34 min_center_NM $controls if cat_income == `x', absorb(cohort#comuna_cod) vce(robust)
	local beta_takeup_`x' = -_b[min_center_NM]*100
	local ub_takeup_`x' = (-_b[min_center_NM] + _se[min_center_NM]*invnormal(0.975))*100
	local lb_takeup_`x' = (-_b[min_center_NM] - _se[min_center_NM]*invnormal(0.975))*100		
}

drop cat_income

*Figure: Take-up effects
preserve
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
	ytitle("Effect on take-up (in %)")  xtitle("") legend(off) ///
	xlabel(1 "Low-income" 3 "High-income", noticks) ///
	ylabel(, nogrid)  ///
	text(1.7 1.6  "Overall effect = `beta_takeup' pp (S.E. = `se_beta_takeup')", place(e) color(blue*.8) size(medsmall)) ///
	graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white))  ///
	plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
	scheme(s2mono) scale(1.2) yline(0, lpattern(dash) lcolor(black))
	

graph export "$results/take-up_low_high_corte`corte'.pdf", as(pdf) replace

restore

}





