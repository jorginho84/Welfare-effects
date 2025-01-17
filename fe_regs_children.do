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

*----------------------*
*---------PREP---------*
*----------------------*


use "$db/data_estimate", clear

// global controls i.m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home
global controls m_age m_college WAIS_t_num WAIS_t_vo f_home dum_young_siblings  /*PESO TALLA*/ controles dum_smoke dum_alc

*--------------------------------------*
**# Effects by age (figures) ----------*
*--------------------------------------*


*Names for graphs
local x = 1
foreach names in "Battelle" "TVIP"{
	local name_`x' = "`names'"
	local x = `x' + 1
	
}

local x = 1
foreach depvar in "battelle" "tvip"{
	preserve
	foreach age of numlist 3 6 {
		reghdfe `depvar'`age' min_center_NM $controls , absorb(cohort#comuna_cod) vce(cluster comuna_cod)
		local beta_takeup_`age' = string(round(-_b[min_center_NM]*100,.001),"%9.3f")
		local ub_takeup_`age' = (-_b[min_center_NM] + _se[min_center_NM]*invnormal(0.975))*100
		local lb_takeup_`age' = (-_b[min_center_NM] - _se[min_center_NM]*invnormal(0.975))*100
		local tstat = _b[min_center_NM] / _se[min_center_NM]
		local pval_`age' = 2*(1-normal(abs(`tstat')))
	}			
	
	clear
	set obs  3
	gen effects = .
	gen lb = .
	gen ub = .
	replace effects = `beta_takeup_3' if _n == 1
	replace lb = `lb_takeup_3' if _n == 1
	replace ub = `ub_takeup_3' if _n == 1

	replace effects = `beta_takeup_6' if _n == 3
	replace lb = `lb_takeup_6' if _n == 3
	replace ub = `ub_takeup_6' if _n == 3
	
	*Valores mostrados en el graf:
	foreach g in 3 6{	
	*di `pval'
	if `pval_`g'' <= 0.01{
		local stars_`g' = "***"
		
	}
	else if `pval_`g'' <= 0.05{
		local stars_`g' = "**"
	}
	else if `pval_`g'' <= 0.1{
		local stars_`g' = "*"
	}
	else{
		local stars_`g' = " "
	}
	}
	*Position of text
	local beta3_pos = `beta_takeup_3' + .2
	local beta6_pos = `beta_takeup_6' + .2
	
	egen x = seq()

	twoway (bar effects x, barwidth(1.2) color(black*.7) fintensity(.5)  lwidth(0.4) ) ///
	(scatter effects x, msymbol(circle) mcolor(black*.7) mfcolor(black*.7)) ///
		(rcap ub lb x, lpattern(solid) lcolor(black*.7) ), ///
		ytitle("Effect on `name_`x'' (in % of {&sigma})")  xtitle("") legend(off) ///
		xlabel(1 "Ages 3-5" 3 "Ages 6-11", noticks) ///
		ylabel(-2(2)4, nogrid)  ///
		graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white))  ///
		plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
		scheme(s2mono) scale(1.7) yline(0, lpattern(dash) lcolor(black)) ///
		text(`beta3_pos' 1.02  "{&beta} = `beta_takeup_3'%`stars_3'" `beta6_pos' 3.02  "{&beta} = `beta_takeup_6'%`stars_6' ", place(ne) color(blue*.8) size(vsmall)) 
		
		
		

	graph export "$results/fe_estimates_`depvar'_short-longterm.pdf", as(pdf) replace

	restore

	local x = `x' + 1
}





