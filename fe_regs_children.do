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

global controls i.m_educ WAIS_t_num WAIS_t_vo m_age dum_young_siblings risk f_home






**Effects by age (figures)


*En caso de que niño/a tenga dos valores en tescore, se promedian.
*test3 == edad 3 a 5. test6 == edades 6 +
egen battelle3 = rowmean(battelle_age3_z battelle_age4_z battelle_age5_z)
egen tvip3 = rowmean(tvip_age3_z tvip_age4_z tvip_age5_z)
egen cbcl3 = rowmean(cbcl*_age3_z cbcl*_age4_z cbcl*_age5_z)

egen battelle6 = rowmean(battelle_age6_z battelle_age7_z battelle_age8_z battelle_age9_z battelle_age10_z battelle_age11_z)
egen tvip6 = rowmean(tvip_age6_z tvip_age7_z tvip_age8_z tvip_age9_z tvip_age10_z tvip_age11_z)
egen cbcl6 = rowmean(cbcl*_age6_z cbcl*_age7_z cbcl*_age8_z cbcl*_age9_z cbcl*_age10_z cbcl*_age11_z)

*Names for graphs
local x = 1
foreach names in "Batelle" "TVIP"{
	local name_`x' = "`names'"
	local x = `x' + 1
	
}

local x = 1
foreach depvar in "battelle" "tvip"{

	preserve
	foreach age of numlist 3 6 {
		qui: reghdfe `depvar'`age' min_center_NM $controls , absorb(cohort#comuna_cod) vce(cluster comuna_cod)
		local beta_takeup_`age' = -_b[min_center_NM]
		local ub_takeup_`age' = (-_b[min_center_NM] + _se[min_center_NM]*invnormal(0.975))
		local lb_takeup_`age' = (-_b[min_center_NM] - _se[min_center_NM]*invnormal(0.975))
			
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

	egen x = seq()

	twoway (bar effects x, barwidth(1.2) color(black*.7) fintensity(.5)  lwidth(0.4) ) ///
	(scatter effects x, msymbol(circle) mcolor(black*.7) mfcolor(black*.7)) ///
		(rcap ub lb x, lpattern(solid) lcolor(black*.7) ), ///
		ytitle("Effect on `name_`x''")  xtitle("") legend(off) ///
		xlabel(1 "Ages 3-5" 3 "Ages 6-11", noticks) ///
		ylabel(-0.02(0.02)0.04, nogrid)  ///
		graphregion(fcolor(white) ifcolor(white) lcolor(white) ilcolor(white))  ///
		plotregion(fcolor(white) lcolor(white)  ifcolor(white) ilcolor(white))  ///
		scheme(s2mono) scale(1.7) yline(0, lpattern(dash) lcolor(black))
		
		

	graph export "$results/fe_estimates_`depvar'_short-longterm.pdf", as(pdf) replace

	restore

	local x = `x' + 1
}





