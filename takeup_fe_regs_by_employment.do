/*
Effects across employment at baseline on take-up
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

// global controls i.m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home
global controls m_age m_college WAIS_t_num WAIS_t_vo f_home dum_young_siblings  /*PESO TALLA*/ controles dum_smoke dum_alc

*----------------------*
*---------PREP---------*
*----------------------*


// recode elegible_t02 (0 = 2) , gen(cat_income)
recode d_work_t02 (0 = 1) (1 = 2) , gen(cat_income) //Low income = did not work 2 years before birth. 



/*--------------------------------------------------------------------------------*/
/*----------------   Effects across income       ----------------------------------*/
/*--------------------------------------------------------------------------------*/

**#Takeup

*By income
forvalues x = 1/2{
	reghdfe public_34 min_center_NM $controls if cat_income == `x', absorb(cohort#comuna_cod) vce(robust)
	local beta_takeup_`x' =  string(round(-_b[min_center_NM]*100,.01),"%9.2f")
	local ub_takeup_`x' = (-_b[min_center_NM] + _se[min_center_NM]*invnormal(0.975))*100
	local lb_takeup_`x' = (-_b[min_center_NM] - _se[min_center_NM]*invnormal(0.975))*100	
		local tstat = _b[min_center_NM] / _se[min_center_NM]
		local pval = 2*(1-normal(abs(`tstat')))
	if `pval' <= 0.01{
		local stars_`x' = "***"
		
	}
	else if `pval' <= 0.05{
		local stars_`x' = "**"
	}
	else if `pval' <= 0.1{
		local stars_`x' = "*"
	}
	else{
		local stars_`x' = " "
	}
}


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

	*Position of text
	local beta1_pos = `beta_takeup_1' + .05
	local beta2_pos = `beta_takeup_2' + .05

egen x = seq()

twoway (bar effects x, barwidth(1.4) color(black*.7) fintensity(.5)  lwidth(0.4) ) ///
(scatter effects x, msymbol(circle) mcolor(black*.7) mfcolor(black*.7)) ///
	(rcap ub lb x, lpattern(solid) lcolor(black*.7) ), ///
	ytitle("Effect on take-up (in %)")  xtitle("") legend(off) ///
	xlabel(1 "Unemployed" 3 "Employed", noticks) xscale(range(0.5 4)) ///
	ylabel(0(1)4, nogrid) yscale(range(0 .)) ///
	graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white))  ///
	plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
	scheme(s2mono) scale(1.9) yline(0, lpattern(dash) lcolor(black)) ///
	text(`beta1_pos' 1  "{&beta}=`beta_takeup_1'%`stars_1'" `beta2_pos' 3  "{&beta}=`beta_takeup_2'%`stars_2'", place(ne) color(blue*.8) size(medsmall)) 
	

graph export "$results/take-up_low_high.pdf", as(pdf) replace

restore
